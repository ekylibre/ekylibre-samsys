# frozen_string_literal: true

module Samsys
  module Handlers
    class RideSets
      VENDOR = ::Samsys::Handlers::VENDOR

      def initialize(stopped_on:, started_on:)
        @stopped_on = stopped_on
        @started_on = started_on
      end

      def bulk_find_or_create
        fetch_all_machines.each do |machine|
          next if get_machine_activities(machine[:id]).empty?

          machine_equipment = find_or_create_machine_equipment(machine)

          find_or_create_ride_set(machine[:id], machine_equipment)
        end
      end

      def delete_ride_sets_without_rides
        ride_set_empty = RideSet.select{|c| c.rides.count == 0}
        RideSet.delete(ride_set_empty) if ride_set_empty.any?
      end

      private

        def fetch_all_machines
          ::Samsys::Data::Machines.new.result
        end

        def get_machine_activities(machine_id)
          ::Samsys::Data::MachineActivities.new(
            machine_id: machine_id, stopped_on: @stopped_on, started_on: @started_on
          ).result.sort_by{ |h| h[:start_date] }
        end

        def find_or_create_machine_equipment(machine)
          sensor_equipment = if machine[:associations].present?
                               Equipment.of_provider_vendor(VENDOR).of_provider_data(:id, machine[:associations].first[:counter].to_s).first
                             else
                               nil
                             end

          # Find or create machine_equipment throught handers/machines_equipments.rb
          machine_equipment = ::Samsys::Handlers::MachinesEquipments.new
          machine_equipment.bulk_find_or_create(machine, sensor_equipment)
        end

        def find_or_create_ride_set(machine_id, machine_equipment)
          get_machine_activities(machine_id).each do |machine_activity|
            next if find_existant_ride_set(machine_activity, machine_equipment).present?

            create_ride_set(machine_activity, machine_equipment)
          end
        end

        def find_existant_ride_set(machine_activity, machine_equipment)
          ride_set = RideSet.of_provider_vendor(VENDOR).of_provider_data(:id, machine_activity[:id].to_s).first

          if ride_set.present?
            ride = ::Samsys::Handlers::Rides.new(ride_set: ride_set, machine_equipment: machine_equipment)
            ride.bulk_find_or_create
          end
        end

        def create_ride_set(machine_activity, machine_equipment)
          ride_set = RideSet.create!(
            started_at: machine_activity[:start_date],
            stopped_at: machine_activity[:end_date],
            road: machine_activity[:road].to_d,
            nature: machine_activity[:type],
            sleep_count: machine_activity[:sleep_count],
            duration: machine_activity[:duration].to_i.seconds,
            sleep_duration: machine_activity[:sleep_duration].to_i.seconds,
            area_without_overlap: machine_activity[:area_without_overlap],
            area_with_overlap: machine_activity[:area_with_overlap],
            area_smart: machine_activity[:area_smart],
            gasoline: machine_activity[:gasoline],
            provider: { vendor: VENDOR, name: 'samsys_ride_set', data: { id: machine_activity[:id] } }
          )

          ride = ::Samsys::Handlers::Rides.new(ride_set: ride_set, machine_equipment: machine_equipment)

          ride.bulk_find_or_create

          shape_line_with_buffer = ::Charta.make_line(ride_set.crumbs.order(:read_at).pluck(:geolocation)).simplify(0.0001).to_rgeo.buffer(1)
          ride_set.update!(shape: shape_line_with_buffer)
        end

    end
  end
end
