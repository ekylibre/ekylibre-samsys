module Backend
  class RideSetsController < Backend::BaseController
    manage_restfully

    unroll

    list(order: { started_at: :desc }) do |t|
      t.column :number, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :decorated_duration
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :decorated_sleep_duration
      t.column :road, class: 'center'
      t.column :equipment
      t.column :provider_vendor
    end

    list(:rides, selectable: true, model: :ride, conditions: { ride_set_id: 'params[:id]'.c }, order: 'rides.started_at DESC') do |t|
      t.column :number, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :decorated_duration
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :decorated_sleep_duration
      t.column :equipment_name, url: { controller: 'backend/equipments', id: 'RECORD.product_id'.c }
    end

    def index
      notify_ride_set_information

      super
    end

    def show
      notify_ride_set_intervention_information

      super
    end
    
    private

      def notify_ride_set_intervention_information
        notify_warning_now(:ride_set_intervention_information.tl)
      end

      def notify_ride_set_information
        if RideSet.count.zero?
          notify_warning_now(helpers.link_to(:ride_set_message.tl, backend_integrations_path))
        else
          notify_now(:ride_set_to_ride_information.tl)
        end
      end
  end
end