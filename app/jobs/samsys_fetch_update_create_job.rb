class SamsysFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(stopped_on:, started_on:, user_id: nil)
    Preference.set!(:samsys_fetch_job_running, true, :boolean)
    begin
      # create custom field for all equipement if not exist
      machine_custom_fields = ::Samsys::Handlers::MachineCustomFields.new
      machine_custom_fields.bulk_find_or_create

      ::Samsys::Handlers::CultivablesZonesAtSamsys.new.create_cultivables_zones_at_samsys

      sensors = ::Samsys::Handlers::Sensors.new
      sensors.bulk_find_or_create

      ride_sets = ::Samsys::Handlers::RideSets.new(stopped_on: stopped_on, started_on: started_on)
      ride_sets.bulk_find_or_create
      ride_sets.delete_ride_sets_without_rides
    rescue StandardError => error
      Rails.logger.error $ERROR_INFO
      Rails.logger.error $ERROR_INFO.backtrace.join("\n")
      ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
      @error = error
    end
    if (user = User.find_by_id(user_id))
      ActionCable.server.broadcast("main_#{user.email}", event: 'update_job_over')
      notif_params =  if @error.nil?
                        correct_samsys_fetch_params
                      else
                        errors_samsys_fetch_params
                      end
      locale = user.language.present? ? user.language.to_sym : :eng
      I18n.with_locale(locale) do
        user.notifications.create!(notif_params)
      end
    end
    Preference.set!(:samsys_fetch_job_running, false, :boolean)
  end

  private

    def errors_samsys_fetch_params
      {
        message: :failed_samsys_fetch_params.tl,
        level: :error,
        interpolations: {}
      }
    end

    def correct_samsys_fetch_params
      {
        message: :correct_samsys_fetch_params.tl,
        level: :success,
        target_url: '/backend/ride_sets',
        interpolations: {}
      }
    end

end
