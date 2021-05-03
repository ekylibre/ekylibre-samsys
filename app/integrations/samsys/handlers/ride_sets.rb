# frozen_string_literal: true

module Integrations
  module Samsys
    module Handlers
      class RideSets
        def initialize(to_ekylibre_machine_type:, default_born_at:, vendor:)
          @to_ekylibre_machine_type = to_ekylibre_machine_type
          @default_born_at = default_born_at
          @vendor = vendor
        end

        def bulk_find_or_create
          fetch_all_machines.each do |machine|
            next if get_machine_activities(machine[:id]).empty?

            machine_equipment = find_or_create_machine_equipment(machine)

            find_or_create_ride_set(machine[:id], machine_equipment)
          end
        end

        private 

        def fetch_all_machines
          Integrations::Samsys::Data::Machines.new.result
        end

        def get_machine_activities(machine_id)
          Integrations::Samsys::Data::MachineActivities.new(
            machine_id: machine_id
          ).result.sort_by{ |h| h[:start_date] }.reverse
        end

        def find_or_create_machine_equipment(machine)
          sensor_equipment = Equipment.of_provider_vendor(@vendor).of_provider_data(:id, machine[:associations].first[:counter].to_s).first

          # Find or create machine_equipment throught handers/machines_equipments.rb
          machine_equipment = Integrations::Samsys::Handlers::MachinesEquipments.new(
            to_ekylibre_machine_type: @to_ekylibre_machine_type, 
            default_born_at: @default_born_at,
            vendor: @vendor
          )
          machine_equipment.bulk_find_or_create(machine, sensor_equipment)
        end

        def find_or_create_ride_set(machine_id, machine_equipment)
          get_machine_activities(machine_id).each do |machine_activity|
            next if find_existant_ride_set(machine_activity, machine_equipment).present?

            create_ride_set(machine_activity, machine_equipment)
          end
        end

        def find_existant_ride_set(machine_activity, machine_equipment)
          ride_set = RideSet.of_provider_vendor(@vendor).of_provider_data(:id, machine_activity[:id].to_s).first

          ride = Integrations::Samsys::Handlers::Rides.new(ride_set: ride_set, machine_equipment: machine_equipment, vendor: @vendor)
          ride.bulk_find_or_create
        end

        def create_ride_set(machine_activity, machine_equipment)
          ride_set = RideSet.create!(
            started_at: machine_activity[:start_date],
            stopped_at: machine_activity[:end_date],
            road: machine_activity[:road],
            nature: machine_activity[:type],
            sleep_count: machine_activity[:sleep_count],
            duration: machine_activity[:duration].to_i.seconds,
            sleep_duration: machine_activity[:sleep_duration].to_i.seconds,
            area_without_overlap: machine_activity[:area_without_overlap],
            area_with_overlap: machine_activity[:area_with_overlap],
            area_smart: machine_activity[:area_smart],
            gasoline: machine_activity[:gasoline],
            provider: { vendor: @vendor, name: "samsys_ride_set", data: { id: machine_activity[:id] } }
          )

          ride = Integrations::Samsys::Handlers::Rides.new(ride_set: ride_set, machine_equipment: machine_equipment, vendor: @vendor)
          ride.bulk_find_or_create
        end

      end
    end
  end
end
  