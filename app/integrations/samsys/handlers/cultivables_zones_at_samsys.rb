# frozen_string_literal: true

module Integrations
  module Samsys
    module Handlers
      class CultivablesZonesAtSamsys

        # FIND cultivablesZones / Parcel matching beetween Ekylibre and Samsys
        def find_matching_fields_at_samsys
          Integrations::Samsys::Data::Fields.new.result.map do |field|
            field_shape_samsys = Charta.new_geometry(field)
            CultivableZone.shape_matching(field_shape_samsys, 0.02).ids
          end
        end

        # Find Samsys current User ID

        # Create cultivale zones at samsys


        private 

        def create_cultivables_zones_at_samsys(cultivables_zones_matching_with_samsys, user_id)
          cultivables_zones_to_create_at_samsys = CultivableZone.where.not(id: cultivables_zones_matching_with_samsys)
          cultivables_zones_to_create_at_samsys .each do |cultivable_zone|
            Samsys::SamsysIntegration.post_parcels(
              user_id,
              cultivable_zone.name,
              cultivable_zone.created_at,
              cultivable_zone.shape.to_rgeo.coordinates.first,
              cultivable_zone.uuid
            ).execute
          end
        end

      end
    end
  end
end
