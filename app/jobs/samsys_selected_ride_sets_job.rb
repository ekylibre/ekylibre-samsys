class SamysDeleteSelectedRideSetsJob < ActiveJob::Base
  queue_as :default

  def perform(ride_set_ids:, user_id: nil)
    user = User.find(user_id) if user_id
    if ride_set_ids
      begin
        ride_sets = RideSet.where(id: ride_set_ids)
        ride_sets.destroy_all
      rescue StandardError => error
        Rails.logger.error $ERROR_INFO
        Rails.logger.error $ERROR_INFO.backtrace.join("\n")
        ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
        @error = error.message
      end
      if user
        ActionCable.server.broadcast("main_#{user.email}", event: 'update_job_over')
        if @error.present?
          user.notifications.create!(errors_destroying_ride_sets)
        else
          user.notifications.create!(success_samsys_destroying_ride_sets(ride_set_ids))
        end
      end
    end
  end

  private

    def success_samsys_destroying_ride_sets(ride_set_ids)
      {
        message: :success_samsys_destroying_ride_sets.tl,
        level: :success,
        interpolations: { count: ride_set_ids.count }
      }
    end

    def errors_destroying_ride_sets
      {
        message: :failed_destroying_ride_sets.tl,
        level: :error,
        interpolations: { message: @error }
      }
    end
end
  