# frozen_string_literal: true

module Samsys
  module Handlers
    class Crumbs
      VENDOR = ::Samsys::Handlers::VENDOR

      def initialize(ride_id:, work_id:, work_breaks:)
        @ride_id = ride_id
        @work_id = work_id
        @work_breaks = work_breaks
        @work_geolocations_size = fetch_all_work_geolocations.size
      end

      def bulk_find_or_create_crumb
        fetch_all_work_geolocations.each_with_index do |work_geolocation, index|
          next if find_existant_crumb(work_geolocation).present?

          create_crumb(work_geolocation, index)
        end
      end

      def bulk_find_or_create_crumb_break
        @work_breaks.each do |work_break|
          next if find_existant_crumb_break(work_break).present?

          create_crumb_break(work_break)
        end
      end

      private

        def fetch_all_work_geolocations
          ::Samsys::Data::WorksGeolocations.new(work_id: @work_id).result
        end

        def find_existant_crumb(work_geolocation)
          Crumb.of_provider_vendor(VENDOR).of_provider_data(:id, work_geolocation[:id_data].to_s).where(ride_id: @ride_id).first
        end

        def create_crumb(work_geolocation, index)
          lat_lon = work_geolocation[:geometry][:coordinates]
          geolocation_crumb = Charta.new_point(lat_lon[1], lat_lon[0]).to_rgeo
          nature_crumb = if index == 0
                           'hard_start'
                         elsif index == (@work_geolocations_size - 1)
                           'hard_stop'
                         else
                           'point'
                         end

          crumb = Crumb.create!(
            nature: nature_crumb,
            device_uid: 'samsys',
            accuracy: 4,
            geolocation: geolocation_crumb,
            read_at: work_geolocation[:properties][:t],
            ride_id: @ride_id,
            provider: { vendor: VENDOR, name: 'samsys_crumb',
  data: { id: work_geolocation[:id_data], speed: work_geolocation[:properties][:speed] } },
          )
        end

        def find_existant_crumb_break(work_break)
          Crumb.of_provider_name(VENDOR, 'samsys_crumb_break').of_provider_data(:start_date, work_break[:start_date].to_s).first
        end

        def create_crumb_break(work_break)
          lat_lon = work_break[:geometry][:coordinates]
          geolocation_break = Charta.new_point(lat_lon[1], lat_lon[0]).to_rgeo

          crumb = Crumb.create!(
            nature: 'pause',
            device_uid: 'samsys',
            accuracy: 4,
            geolocation: geolocation_break,
            read_at: work_break[:start_date],
            metadata: { 'duration' => work_break[:duration], 'start_date' => work_break[:start_date], 'end_date' => work_break[:end_date] },
            ride_id: @ride_id,
            provider: { vendor: VENDOR, name: 'samsys_crumb_break', data: { start_date: work_break[:start_date] } },
          )
        end

    end
  end
end
