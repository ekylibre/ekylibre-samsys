# frozen_string_literal: true

module Samsys
  module Data 
    class MachineActivities
      def initialize(machine_id:, stopped_on:)
        @machine_id = machine_id
        @stopped_on = stopped_on.strftime("%FT%TZ")
        @started_on = (stopped_on - 30.days).strftime("%FT%TZ")
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
          field.filter{ |k, v| desired_fields.include?(k) }
        end
      end

      def desired_fields
        [:id, :start_date, :end_date, :road, :type, :sleep_count, :duration, :sleep_duration, :area_without_overlap, :area_with_overlap, :area_smart, :gasoline]
      end

    end
  end
end
    