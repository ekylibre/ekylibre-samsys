# frozen_string_literal: true

module Samsys
  module Handlers
    class Ride
      VENDOR = ::Samsys::Handlers::VENDOR
      DEFAULT_TOOL_WIDTH = 2.0

      def initialize(ride_set:, meta_work:, machine_equipment:, field:)
        @ride_set = ride_set
        @meta_work = meta_work
        @machine_equipment = machine_equipment
        @field = field
      end

      def bulk_find_or_create
        return if find_existant_ride.present?

        create_ride
      end

      private
        attr_reader :ride_set, :meta_work, :machine_equipment, :field

        def tool_width
          equipment_width = machine_equipment.get(:application_width).in(:meter).to_f
          return DEFAULT_TOOL_WIDTH if (equipment_width == 0.0 || equipment_width.nil?)

          equipment_width
        end

        def find_existant_ride
          ride = ::Ride.of_provider_vendor(VENDOR).of_provider_data(:id, meta_work[:id].to_s).first

          # Update ride's ride_set_id with new id from samsys's update
          ride.update!(ride_set_id: @ride_set.id) if ride.present? && ride.ride_set_id != @ride_set.id

          if ride.present?
            find_or_create_crumbs(ride.id, meta_work[:id], meta_work[:breaks])
            find_or_create_crumbs_breaks(ride.id, meta_work[:id], meta_work[:breaks]) if meta_work[:breaks].present?
          end

          ride
        end

        def cultivable_zone
          return unless field

          CultivableZone.shape_matching(Charta.new_geometry(field)).first
        end

        def create_ride
          ride = ::Ride.create!(
            started_at: meta_work[:start_date],
            stopped_at: meta_work[:end_date],
            duration: meta_work[:duration].to_i.seconds,
            sleep_count: meta_work[:sleep_count],
            sleep_duration: meta_work[:sleep_duration].to_i.seconds,
            nature: meta_work[:type],
            distance_km: meta_work[:distance_km],
            area_without_overlap: meta_work[:area_without_overlap],
            area_with_overlap: meta_work[:area_with_overlap],
            area_smart: meta_work[:area_smart],
            gasoline: meta_work[:gasoline],
            product_id: machine_equipment.id,
            ride_set_id: ride_set.id,
            provider: { vendor: VENDOR, name: 'samsys_ride',
  data: { id: meta_work[:id], machine_equipment_tool_width: tool_width } },
          )

          if cultivable_zone.present?
            ride.cultivable_zone = cultivable_zone
          end

          find_or_create_crumbs(ride.id, meta_work[:id], meta_work[:breaks])
          find_or_create_crumbs_breaks(ride.id, meta_work[:id], meta_work[:breaks]) if meta_work[:breaks].present?

          line_shape = set_shape_line(ride)
          ride.update!(shape: line_shape)
        end

        def initialize_crumbs(ride_id, meta_work_id, meta_work_breaks)
          ::Samsys::Handlers::Crumbs.new(ride_id: ride_id, work_id: meta_work_id, work_breaks: meta_work_breaks)
        end

        def find_or_create_crumbs(ride_id, meta_work_id, meta_work_breaks)
          crumbs = initialize_crumbs(ride_id, meta_work_id, meta_work_breaks)
          crumbs.bulk_find_or_create_crumb
        end

        def find_or_create_crumbs_breaks(ride_id, meta_work_id, meta_work_breaks)
          crumbs_breaks = initialize_crumbs(ride_id, meta_work_id, meta_work_breaks)
          crumbs_breaks.bulk_find_or_create_crumb_break
        end

        # Method needed in case Samsys send ride with only 1 geolocation point
        def set_shape_line(ride)
          crumbs = ride.crumbs.order(:read_at).pluck(:geolocation)

          line_shape = if crumbs.size > 1
                         crumbs
                       else
                         crumbs << crumbs.first
                         crumbs
                       end

          Charta.make_line(line_shape)
        end
    end
  end
end
