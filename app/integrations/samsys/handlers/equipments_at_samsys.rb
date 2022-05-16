# frozen_string_literal: true

module Samsys
  module Handlers
    class EquipmentsAtSamsys
      VENDOR = ::Samsys::Handlers::VENDOR

      # transcode Samsys machine type in Ekylibre machine variant
      # row 0 : Ekylibre variant reference name
      # row 1 : Samsys machine type
      MACHINE_TYPE_FILE_NAME = 'samsys_ekylibre_machine_types.csv'

      def create_equipments_at_samsys
        here = Pathname.new(__FILE__).dirname

        to_machine_type = {}.with_indifferent_access
        CSV.foreach(here.join(MACHINE_TYPE_FILE_NAME), headers: true) do |row|
          to_machine_type[row[0].to_s] = row[1].to_s
        end

        equipments_to_create_at_samsys = Equipment.where.not(variety: 'connected_object') - Equipment.where.not(variety: 'connected_object').of_provider_vendor('samsys')
        equipments_to_create_at_samsys.each do |equipment|
          brand = ((equipment.custom_fields? && equipment.custom_fields.key?("brand_name") && equipment.custom_fields["brand_name"].present?) ? equipment.custom_fields["brand_name"] : 'Inconnue')
          mod = ((equipment.custom_fields? && equipment.custom_fields.key?("mod_name") && equipment.custom_fields["mod_name"].present? ) ? equipment.custom_fields["mod_name"] : 'Inconnue')
          ::Samsys::SamsysIntegration.post_machines(
            equipment.name,
            to_machine_type[equipment.variant.reference_name],
            samsys_current_cluster_id,
            brand,
            mod,
            equipment.uuid,
            equipment.get(:application_width).in(:meter).to_f,
            equipment.get(:ground_speed).in(:kilometer_per_hour).to_f).execute do |c|
            c.success do |response|
              equipment.provider = { vendor: VENDOR, name: 'samsys_equipment', data: { id: response[:id].to_s } }
              equipment.save
            end
            c.error do |response|
              Rails.logger.error response
            end
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
