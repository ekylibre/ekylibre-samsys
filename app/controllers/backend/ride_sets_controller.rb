module Backend
  class RideSetsController < Backend::BaseController
    manage_restfully

    unroll

    list do |t|
      t.column :number, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :duration_iso
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :sleep_duration_iso
      t.column :road, class: 'center'
      t.column :equipment
      t.column :provider_vendor
    end

    list(:rides, model: :ride, conditions: { ride_set_id: 'params[:id]'.c }) do |t|
      t.column :number, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration, label_method: :duration_iso
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration, label_method: :sleep_duration_iso
      t.column :equipment_name, url: { controller: 'backend/equipments', id: 'RECORD.product_id'.c }
    end

    def index
      notify_ride_set_creation_warning

      super
    end

    private

      def notify_ride_set_creation_warning
        if RideSet.count.zero?
          notify_warning_now(helpers.link_to(:ride_set_message.tl, backend_integrations_path))
        end
      end
  end
end