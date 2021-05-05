class SamsysFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  VENDOR = 'samsys'.freeze

  def perform
    begin
      # create custom field for all equipement if not exist
      machine_custom_fields = Integrations::Samsys::Handlers::MachineCustomFields.new
      machine_custom_fields.bulk_find_or_create

      Integrations::Samsys::Handlers::CultivablesZonesAtSamsys.new.create_cultivables_zones_at_samsys

      sensors = Integrations::Samsys::Handlers::Sensors.new(vendor: VENDOR)
      sensors.bulk_find_or_create

      ride_sets = Integrations::Samsys::Handlers::RideSets.new(vendor: VENDOR)
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
