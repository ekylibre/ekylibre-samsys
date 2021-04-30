# frozen_string_literal: true

module Integrations
  module Samsys
    module Handlers
      class MachinesEquipments
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

        
        def bulk_find_or_create(machine, counter, sensor_equipment)
          machine_equipment = find_or_create_machine_equipment(machine, counter)

          custom_field = CustomField.find_by(column_name: "brand_name")
          machine_equipment.set_custom_value(custom_field, machine[:brand])

          # Get geolocation for a machine
          machine_geolocation(machine_id, machine_equipment)
      
          # Link the sensor to the machine
          link_sensor_to_machine(sensor_equipment, machine_equipment)
        end
  
        private 

        def find_or_create_machine_equipment(machine, counter)
          machine_equipment = Equipment.of_provider_vendor(@vendor).of_provider_data(:id, machine[:id].to_s).first

          if machine_equipment.present?
            sensor_equipment
          else
            create_machine_equipment(counter, machine)
          end    
        end

        def create_machine_equipment(counter, machine)
          owner = owner_entity(counter)
          equipment_variant = variant_to_find(@to_ekylibre_machine_type, machine[:machine_type])

          machine_equipment = Equipment.create!(
            variant_id: equipment_variant.id,
            name: machine[:name],
            initial_born_at: @default_born_at,
            initial_population: 1,
            initial_owner: owner,
            work_number: "SAMSYS_#{machine[:id]}",
            provider: {vendor: "Samsys", name: "samsys_equipment", data: { id: machine[:id] }}
          )
        end

        def owner_entity(counter)
          if counter[:owner][:type_cluster] == "farm"
            Entity.of_company
          elsif counter[:owner][:type_cluster] != "farm"
            #TODO create the entity
          end
        end

        def variant_to_find(to_ekylibre_machine_type, machine_type)
          variant_to_find = to_ekylibre_machine_type[machine_type.downcase]

          if variant_to_find
            ProductNatureVariant.import_from_nomenclature(variant_to_find)
          else
            ProductNatureVariant.import_from_nomenclature(:tractor)
          end
        end

        def machine_geolocation(machine_id, machine_equipment)
          machine_geolocation = Integrations::Samsys::Data::MachineGeolocation.new(machine_id: machine_id).result

          if machine_geolocation[:geometry][:coordinates].present? && machine_equipment.variant.has_indicator?(:geolocation)
            lat_lon = geolocation[:geometry][:coordinates]
            point = ::Charta.new_point(lat_lon[1], lat_lon[0]).to_ewkt
            read_at = geolocation[:properties][:t]
            machine_equipment.read!(:geolocation, point, at: read_at, force: true) if point && read_at
          end
        end

        def link_sensor_to_machine(sensor_equipment, machine_equipment)
          if sensor_equipment && machine_equipment
            ProductLink.find_or_create_by(
              product_id: sensor_equipment.id,
              linked_id: machine_equipment.id,
              nature: "sensor",
              started_at: counter[:association][:start_date]
            )
          end
        end

      end
    end
  end
end
