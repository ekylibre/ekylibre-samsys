# frozen_string_literal: true

module Samsys
  module Data
    class MachineActivities
      def initialize(machine_id:, stopped_on:, started_on:)
        @machine_id = machine_id
        @stopped_on = stopped_on.to_time.utc.iso8601
        @started_on = started_on.to_time.utc.iso8601
      end

      def result
        @formated_data ||= call_api
      end

      private

        attr_reader :machine_id, :started_on, :stopped_on

        def call_api
          ::Samsys::SamsysIntegration.fetch_activities_machine(@machine_id, @started_on, @stopped_on).execute do |c|
            c.success do |list|
              format_data(list)
            end
          end
        end

        def format_data(list)
          list.map do |field|
            field.filter{ |k, _v| desired_fields.include?(k) }
          end
        end

        def desired_fields
          %i[id start_date end_date road type sleep_count duration sleep_duration area_without_overlap area_with_overlap
             area_smart gasoline]
        end

    end
  end
end
