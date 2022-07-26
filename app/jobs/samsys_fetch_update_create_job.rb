class SamsysFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(stopped_on:, started_on:, user_id: nil)
    Preference.set!(:samsys_fetch_job_running, true, :boolean)
    begin
      # count ride set before
      count_before = RideSet.count
      # create custom field if not exist
      machine_custom_fields = ::Samsys::Handlers::MachineCustomFields.new
      machine_custom_fields.bulk_find_or_create

      # find or create equipments in Ekylibre from machines in Samsys
      ::Samsys::Data::Machines.new.result.each do |machine|
        machine_equipment = ::Samsys::Handlers::MachinesEquipments.new
        machine_equipment.bulk_find_or_create(machine, nil)
      end
      # find or create equipments in Samsys from Ekylibre equipment without Samsys provider
      #::Samsys::Handlers::EquipmentsAtSamsys.new.create_equipments_at_samsys

      # find or create CZ in Samsys
      #::Samsys::Handlers::CultivablesZonesAtSamsys.new.create_cultivables_zones_at_samsys

      # create sensors
      sensors = ::Samsys::Handlers::Sensors.new
      sensors.bulk_find_or_create

      # Sync ride sets
      ride_sets = ::Samsys::Handlers::RideSets.new(stopped_on: stopped_on, started_on: started_on)
      ride_sets.bulk_find_or_create
      ride_sets.delete_ride_sets_without_rides
      count_after = RideSet.count
      @count = count_after - count_before
    rescue StandardError => error
      Preference.set!(:samsys_fetch_job_running, false, :boolean)
      Rails.logger.error $ERROR_INFO
      Rails.logger.error $ERROR_INFO.backtrace.join("\n")
      ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
      @error = error.message
    end
    user = User.find(user_id) if user_id
    if user
      ActionCable.server.broadcast("main_#{user.email}", event: 'update_job_over')
      if @count.present?
        user.notifications.create!(correct_samsys_fetch_params)
      elsif @error.present?
        user.notifications.create!(errors_samsys_fetch_params)
      end
    end
    Preference.set!(:samsys_fetch_job_running, false, :boolean)
  end

  private

    def errors_samsys_fetch_params
      {
        message: :failed_samsys_fetch_params.tl,
        level: :error,
        interpolations: { message: @error }
      }
    end

    def correct_samsys_fetch_params
      {
        message: :correct_samsys_fetch_params.tl,
        level: :success,
        target_url: '/backend/ride_sets',
        interpolations: { count: @count.to_s}
      }
    end

end
