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

        def testing
          fetch_all_machines_id.each do |m|
            next if get_machine_activites(m).empty?

            machine_activities = get_machine_activites(m)
            # Create machine equipment

            # Create associate RideSet

              # Create associate Ride
                # Create associate Crumbs
          end
        end


        private 

        def fetch_all_machines_id
          Integrations::Samsys::Data::Machines.new.result.map{|m| m[:id]}
        end

        def get_machine_activites(machine_id)
          Integrations::Samsys::Data::MachineActivities.new(machine_id: machine_id).result
        end

      end
    end
  end
end
  