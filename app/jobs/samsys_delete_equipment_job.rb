class SamsysDeleteEquipmentJob < ActiveJob::Base
  queue_as :default

  def perform(equipment_id:, user_id: nil)
    user = User.find(user_id) if user_id
    @equipment = Equipment.find(equipment_id.to_i) if equipment_id
    if @equipment && @equipment.provider? && @equipment.provider_vendor == 'samsys'
      machine_id = @equipment.provider_data[:id]
      begin
        machine = ::Samsys::Data::Machine.new(machine_id)
        machine.delete_machine
      rescue StandardError => error
        Rails.logger.error $ERROR_INFO
        Rails.logger.error $ERROR_INFO.backtrace.join("\n")
        ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
        @error = error.message
      end
      if user
        ActionCable.server.broadcast("main_#{user.email}", event: 'update_job_over')
        if @error.present?
          user.notifications.create!(errors_samsys_fetch_params)
        else
          user.notifications.create!(correct_samsys_fetch_params)
        end
      end
    end
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
        message: :success_destroying_equipment.tl,
        level: :success,
        target_url: "/backend/equipments/#{@equipment.id}"
      }
    end

end
