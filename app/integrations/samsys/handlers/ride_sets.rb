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

        # TO Create Machine Equipment
        # Fetch all Machines from Samsys
        
        # Fetch machine activies 
        # Create Machine Equipment only if a Machine get activities

        # Create Machine Equipment

        def bulk_find_or_create
          fetch_all_machines.each do |machine|
            next if get_machine_activities(machine[:id]).empty?

            machine_equipment = find_or_create_machine_equipment(machine)

            # Create associate RideSet

              # Create associate Ride
                # Create associate Crumbs
          end
        end


        private 

        def fetch_all_machines
          Integrations::Samsys::Data::Machines.new.result
        end

        def get_machine_activities(machine_id)
          Integrations::Samsys::Data::MachineActivities.new(machine_id: machine_id).result
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

      end
    end
  end
end
  