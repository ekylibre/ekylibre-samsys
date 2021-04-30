# frozen_string_literal: true

module Integrations
  module Samsys
    module Handlers
      class Rides
        def initialize(ride_set_id:, machine_equipment:, vendor:)
          @ride_set_id = ride_set_id
          @machine_equipment = machine_equipment
          @vendor = vendor
        end

        def bulk_find_or_create
          fetch_all_machine_activity_meta_works.each do |meta_work|
            next if find_existant_ride(meta_work).present?

            create_ride(meta_work)
          end
        end

        private 

        def fetch_all_machine_activity_meta_works
          Integrations::Samsys::Data::MetaWorks.new(activity_id: @ride_set_id).result
        end

        def find_existant_ride(meta_work)
          ride = Ride.of_provider_vendor(@vendor).of_provider_data(:id, meta_work[:id].to_s).first
        end

        def create_ride(meta_work)
          ride = Ride.create!(
            started_at: meta_work[:start_date],
            stopped_at: meta_work[:end_date],
            duration: meta_work[:duration].to_i.seconds,
            sleep_count: meta_work[:sleep_count],
            sleep_duration: meta_work[:sleep_duration].to_i.seconds,
            equipment_name: @machine_equipment.name,
            state: "unaffected",
            nature: meta_work[:type],
            distance_km: meta_work[:distance_km],
            area_without_overlap: meta_work[:area_without_overlap],
            area_with_overlap: meta_work[:area_with_overlap],
            area_smart: meta_work[:area_smart],
            gasoline: meta_work[:gasoline],
            product_id: @machine_equipment.id,
            ride_set_id: @ride_set_id,
            provider: { vendor: @vendor, name: "samsys_ride", id: meta_work["id"] },
          )
        end

      end
    end
  end
end
    