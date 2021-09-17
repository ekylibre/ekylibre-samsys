# frozen_string_literal: true

module Samsys
  module Data
    class WorksGeolocations
      def initialize(work_id:)
        @work_id = work_id
      end

      def result
        @formated_data ||= call_api
      end

      private

        def call_api
          ::Samsys::SamsysIntegration.fetch_work_geolocations(@work_id).execute do |c|
            c.success do |list|
              format_data(list.sort_by { |c| c[:properties][:t] })
            end
          end
        end

        def format_data(list)
          list.map do |field|
            field.filter{ |k, _v| desired_fields.include?(k) }
          end
        end

        def desired_fields
          %i[id_data geometry properties]
        end

    end
  end
end
