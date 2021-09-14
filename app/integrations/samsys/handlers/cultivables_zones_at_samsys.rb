# frozen_string_literal: true

module Samsys
  module Handlers
    class CultivablesZonesAtSamsys

      def create_cultivables_zones_at_samsys
        cultivables_zones_to_create_at_samsys = CultivableZone.where.not(id: find_matching_fields_at_samsys.flatten.uniq)
        cultivables_zones_to_create_at_samsys.each do |cultivable_zone|
          ::Samsys::SamsysIntegration.post_parcels(
            samsys_current_user[:id],
            cultivable_zone.name,
            cultivable_zone.created_at,
            cultivable_zone.shape.to_rgeo.coordinates.first,
            cultivable_zone.uuid
          ).execute
        end
      end

      private

        def find_matching_fields_at_samsys
          samsys_fields = ::Samsys::Data::Fields.new.result
          return [] if samsys_fields.nil?

          samsys_fields.map do |field|
            field_shape_samsys = Charta.new_geometry(field)
            CultivableZone.shape_matching(field_shape_samsys, 0.02).ids
          end
        end

        def samsys_current_user
          ::Samsys::Data::UserInformation.result
        end

    end
  end
end
