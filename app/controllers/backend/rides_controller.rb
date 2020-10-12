module Backend
  class RidesController < EkylibreSamsys::ApplicationController

    manage_restfully

    unroll
 
    def self.rides_conditions
      search_conditions(rides: [:equipment_name])
    end

    list(conditions: rides_conditions) do |t|
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :started_at
      t.column :stopped_at
      t.column :duration_iso
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration_iso
      t.column :equipment_name, url: { controller: 'backend/equipments', id: 'RECORD.product_id'.c }
      t.column :provider_name
      t.column :state
    end
  end
end