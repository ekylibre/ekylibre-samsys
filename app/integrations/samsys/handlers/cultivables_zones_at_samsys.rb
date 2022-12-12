# frozen_string_literal: true

module Samsys
  module Handlers
    class CultivablesZonesAtSamsys

      def create_cultivables_zones_at_samsys
        cultivables_zones_to_create_at_samsys = CultivableZone.where.not(id: synchronized_cultivables_zones_ids.uniq.flatten)
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

        def synchronized_cultivables_zones_ids
          samsys_fields = ::Samsys::Data::Fields.new.result
          return [] if samsys_fields.nil?

          samsys_fields.map do |field|
            valid_ewkt = ShapeCorrector.build.try_fix_geojson(field['geometry'].to_json, 4326)
            samsys_shape = Charta.new_geometry(Maybe(valid_ewkt).or_else(field)).convert_to(:multi_polygon)

            CultivableZone.shape_matching(samsys_shape, 0.02).ids
          end
        end

        def samsys_current_user
          ::Samsys::Data::UserInformation.result
        end

    end
  end
end
