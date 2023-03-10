# frozen_string_literal: true

module Samsys
  module Data
    class MetaWorks
      def initialize(activity_id:)
        @activity_id = activity_id
      end

      def result
        @formated_data ||= call_api
      end

      def format_data(list)
        list.map do |meta_work|
          meta_work.filter{ |k, _v| desired_fields.include?(k) }
        end
      end

      private

        def call_api
          ::Samsys::SamsysIntegration.fetch_works_activity(@activity_id).execute do |c|
            c.success do |list|
              format_data(list)
            end
          end
        end

        def desired_fields
          %i[id type start_date end_date breaks duration sleep_count sleep_duration type distance_km
             area_without_overlap area_with_overlap area_smart gasoline field machines]
        end

    end
  end
end
