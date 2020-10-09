module Backend
  class RideSetsController < Backend::BaseController
    manage_restfully

    unroll

    list do |t|
      t.column :number, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration_iso
      t.column :sleep_count, class: 'center'
      t.column :sleep_duration_iso
      t.column :road, class: 'center'
      t.column :equipment
      t.column :provider_vendor
    end

    list(:rides, model: :ride, conditions: { ride_set_id: 'params[:id]'.c }) do |t|
      t.column :number, url: true
      t.column :nature
      t.column :started_at
      t.column :stopped_at
      t.column :duration_iso
      t.column :sleep_count
      t.column :sleep_duration_iso
    end
  end
end