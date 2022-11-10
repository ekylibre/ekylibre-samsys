# frozen_string_literal: true

module Samsys
  module Handlers
    class EquipmentsAtSamsys
      VENDOR = ::Samsys::Handlers::VENDOR

      # transcode Samsys machine type in Ekylibre machine variant
      # row 0 : Ekylibre variant reference name
      # row 1 : Samsys machine type
      # row 2 : Default samsys machine type
      # row 3 : Default ekylibre variant (not used in this file)

      EKYLIBRE_VARIANT_SAMSYS_MACHINE_TYPES = 'ekylibre_variant_samsys_machine_types.csv'
      EKYLIBRE_PRODUCT_NATURE_TO_SAMSYS_MACHINE_TYPES = 'ekylibre_product_nature_to_samsys_machine_types.csv'

      def create_equipments_at_samsys
        list_of_equipment_variety = %w[tractor trailed_equipment handling_equipment equipment]
        equipments_to_create_at_samsys = Equipment.where(variety: list_of_equipment_variety) - Equipment.where.not(provider: nil).of_provider_vendor('samsys')

        equipments_to_create_at_samsys.each do |equipment|
          if equipment.variant.reference_name
            here = Pathname.new(__FILE__).dirname

            to_machine_type = {}.with_indifferent_access
            CSV.foreach(here.join(EKYLIBRE_VARIANT_SAMSYS_MACHINE_TYPES), headers: true) do |row|
              if row[2] == '1'
                to_machine_type[row[0].to_s] = row[1].to_s
              end
            end

            post_equipment_at_samsys(equipment, to_machine_type[equipment.variant.reference_name])

          elsif equipment.variant.reference_name.nil? && equipment.variant.nature.reference_name
            samsys_machine_type = find_samsys_machine_type(equipment.variant.nature.reference_name, EKYLIBRE_PRODUCT_NATURE_TO_SAMSYS_MACHINE_TYPES)
            # Create equipment at samsys only if samsys_machine_type is present
            if samsys_machine_type
              post_equipment_at_samsys(equipment, samsys_machine_type)
            end
          else
            samsys_machine_type = find_samsys_machine_type('tractor', EKYLIBRE_PRODUCT_NATURE_TO_SAMSYS_MACHINE_TYPES)
            post_equipment_at_samsys(equipment, samsys_machine_type)
          end
        end
      end

      def find_samsys_machine_type(equipment_product_nature, csv_file)
        here = Pathname.new(__FILE__).dirname

        to_machine_type = {}.with_indifferent_access
        CSV.foreach(here.join(csv_file), headers: true) do |row|
          to_machine_type[row[0].to_s] = row[1].to_s
        end

        to_machine_type[equipment_product_nature]
      end

      def post_equipment_at_samsys(equipment, machine_type)
        brand = ((equipment.custom_fields? && equipment.custom_fields.key?('brand_name') && equipment.custom_fields['brand_name'].present?) ? equipment.custom_fields['brand_name'] : 'Inconnue')
        mod = ((equipment.custom_fields? && equipment.custom_fields.key?('mod_name') && equipment.custom_fields['mod_name'].present? ) ? equipment.custom_fields['mod_name'] : 'Inconnue')
        ::Samsys::SamsysIntegration.post_machines(
          equipment.name,
          machine_type,
          samsys_current_cluster_id,
          brand,
          mod,
          equipment.uuid,
          equipment.get(:application_width).in(:meter).to_f,
          equipment.get(:ground_speed).in(:kilometer_per_hour).to_f
        ).execute do |c|
          c.success do |response|
            equipment.provider = { vendor: VENDOR, name: 'samsys_equipment', data: { id: response[:id].to_s } }
            equipment.save
          end
          c.error do |response|
            Rails.logger.error response
          end
        end
      end

      private

        def samsys_current_cluster_id
          cluster = ::Samsys::Data::Clusters.result
          if cluster.any?
            cluster.first[:id]
          else
            nil
          end
        end

    end
  end
end
