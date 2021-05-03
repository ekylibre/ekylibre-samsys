# frozen_string_literal: true

module Integrations
  module Samsys
    module Handlers
      class Rides
        def initialize(ride_set:, machine_equipment:, vendor:)
          @ride_set = ride_set
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
          Integrations::Samsys::Data::MetaWorks.new(activity_id: @ride_set.provider[:data]["id"]).result
        end

        def find_existant_ride(meta_work)
          ride = Ride.of_provider_vendor(@vendor).of_provider_data(:id, meta_work[:id].to_s).first

          # Update ride's ride_set_id with new id from samsys's update
          ride.update!(ride_set_id: @ride_set.id) if ride.present? && ride.ride_set_id != @ride_set.id

          if ride.present?
            find_or_create_crumbs(ride.id, meta_work[:id], meta_work[:breaks])
            find_or_create_crumbs_breaks(ride.id, meta_work[:id], meta_work[:breaks]) if meta_work[:breaks].present?
          end

          ride
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
            ride_set_id: @ride_set.id,
            provider: { vendor: @vendor, name: "samsys_ride", data: { id: meta_work[:id] } },
          )

          find_or_create_crumbs(ride.id, meta_work[:id], meta_work[:breaks])
          find_or_create_crumbs_breaks(ride.id, meta_work[:id], meta_work[:breaks]) if meta_work[:breaks].present?
        end

        def initialize_crumbs(ride_id, meta_work_id, meta_work_breaks)
          Integrations::Samsys::Handlers::Crumbs.new(ride_id: ride_id, work_id: meta_work_id, work_breaks: meta_work_breaks, vendor: @vendor)
        end

        def find_or_create_crumbs(ride_id, meta_work_id, meta_work_breaks)
          crumbs = initialize_crumbs(ride_id, meta_work_id, meta_work_breaks)
          crumbs.bulk_find_or_create_crumb
        end

        def find_or_create_crumbs_breaks(ride_id, meta_work_id, meta_work_breaks)
          crumbs_breaks = initialize_crumbs(ride_id, meta_work_id, meta_work_breaks)
          crumbs_breaks.bulk_find_or_create_crumb_break
        end

      end
    end
  end
end
    
