# frozen_string_literal: true

module Samsys
  module Handlers
    class MachinesEquipments
      # transcode Samsys machine type in Ekylibre machine variant
      # row 0 : Ekylibre variant reference name
      # row 1 : Samsys machine type
      MACHINE_TYPE_FILE_NAME = 'ekylibre_variant_samsys_machine_types.csv'

      # set default creation date older because we have no date for machine
      DEFAULT_BORN_AT = Time.new(2010, 1, 1, 10, 0, 0, '+00:00')

      VENDOR = ::Samsys::Handlers::VENDOR

      def bulk_find_or_create(machine, sensor_equipment)
        machine_equipment = find_or_create_machine_equipment(machine)

        # Get geolocation for a machine
        machine_geolocation(machine[:id], machine_equipment)

        # Link the sensor to the machine
        if sensor_equipment
          link_sensor_to_machine(sensor_equipment, machine_equipment, machine)
        end

        machine_equipment
      end

      private

        def find_or_create_machine_equipment(machine)
          machine_equipment = Equipment.of_provider_vendor(VENDOR).of_provider_data(:id, machine[:id].to_s).first

          if machine_equipment.present?
            update_machine_equipment_provider(machine_equipment, machine)

            machine_equipment
          else
            create_machine_equipment(machine)
          end
        end

        def create_machine_equipment(machine)
          owner = owner_entity(machine)
          equipment_variant = variant_to_find(machine[:machine_type])

          machine_equipment = Equipment.create!(
            variant_id: equipment_variant.id,
            name: machine[:name],
            initial_born_at: DEFAULT_BORN_AT,
            initial_population: 1,
            initial_owner: owner,
            work_number: "SAMSYS_#{machine[:id]}",
            provider: { vendor: VENDOR, name: 'samsys_equipment', data: { id: machine[:id].to_s } }
          )
          ::Samsys::Handlers::MachineCustomFields::MACHINE_CUSTOM_FIELDS.each do |k, v|
            c_field = v[:options][:column_name]
            f = CustomField.find_by(column_name: c_field)
            machine_equipment.set_custom_value(f, machine[k.to_sym]) if f
          end

          machine_equipment.read!(:application_width, machine[:tool_width].to_f.in_meter, at: Time.now) if machine_equipment.application_width.to_f != machine[:tool_width].to_f
          machine_equipment.read!(:ground_speed, machine[:max_speed].to_f.in_kilometer_per_hour, at: Time.now) if machine_equipment.ground_speed.to_f != machine[:max_speed].to_f

          machine_equipment
        end

        # update application_width in Ekylibre (tool_width in Samsys) && custom_fields
        def update_machine_equipment_provider(machine_equipment, machine)
          ::Samsys::Handlers::MachineCustomFields::MACHINE_CUSTOM_FIELDS.each do |k, v|
            c_field = v[:options][:column_name]
            f = CustomField.find_by(column_name: c_field)
            machine_equipment.set_custom_value(f, machine[k.to_sym]) if f
          end

          machine_equipment.read!(:application_width, machine[:tool_width].to_f.in_meter, at: Time.now) if machine_equipment.application_width.to_f != machine[:tool_width].to_f
          machine_equipment.read!(:ground_speed, machine[:max_speed].to_f.in_kilometer_per_hour, at: Time.now) if machine_equipment.ground_speed.to_f != machine[:max_speed].to_f
        end

        def owner_entity(machine)
          if machine[:cluster][:type_cluster] == 'farm'
            Entity.of_company
          elsif machine[:cluster][:type_cluster] != 'farm'
            # TODO: create the entity
          end
        end

        # find or create variant with Lexicon based on transcode file
        def variant_to_find(machine_type)

          here = Pathname.new(__FILE__).dirname

          to_machine_type = {}.with_indifferent_access
          CSV.foreach(here.join(MACHINE_TYPE_FILE_NAME), headers: true) do |row|
            if row[3] == "1"
              to_machine_type[row[1].to_s] = row[0].to_sym
            end
          end

          ekylibre_reference_name = to_machine_type[machine_type]

          if ekylibre_reference_name
            ProductNatureVariant.import_from_lexicon(ekylibre_reference_name)
          else
            ProductNatureVariant.import_from_lexicon(:tractor)
          end
        end

        def machine_geolocation(machine_id, machine_equipment)
          machine_geolocation = ::Samsys::Data::MachineGeolocation.new(machine_id: machine_id).result
          if machine_geolocation[:geometry][:coordinates].present? && machine_equipment.variant.has_indicator?(:geolocation)
            lat_lon = machine_geolocation[:geometry][:coordinates]
            point = ::Charta.new_point(lat_lon[1], lat_lon[0]).to_ewkt
            read_at = machine_geolocation[:properties][:t]
            machine_equipment.read!(:geolocation, point, at: read_at, force: true) if point && read_at
          end
        end

        def link_sensor_to_machine(sensor_equipment, machine_equipment, machine)
          if sensor_equipment && machine_equipment
            ProductLink.find_or_create_by(
              product_id: sensor_equipment.id,
              linked_id: machine_equipment.id,
              nature: 'sensor',
              started_at: machine[:associations].first[:start_date]
            )
          end
        end

    end
  end
end
