class SamsysFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(stopped_on = Time.now)
    begin
      # create custom field for all equipement if not exist
      machine_custom_fields = ::Samsys::Handlers::MachineCustomFields.new
      machine_custom_fields.bulk_find_or_create

      ::Samsys::Handlers::CultivablesZonesAtSamsys.new.create_cultivables_zones_at_samsys

      sensors = ::Samsys::Handlers::Sensors.new
      sensors.bulk_find_or_create

      ride_sets = ::Samsys::Handlers::RideSets.new(stopped_on: stopped_on)
      ride_sets.bulk_find_or_create
      ride_sets.delete_ride_sets_without_rides

    rescue StandardError => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
    end
  end

  private

  def error_notification_params(error)
    {
      message: 'error_during_samsys_api_call',
      level: :error,
      target_type: '',
      target_url: '',
      interpolations: {
        error_message: error
      }
    }
  end
end
