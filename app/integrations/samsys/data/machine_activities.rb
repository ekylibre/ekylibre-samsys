# frozen_string_literal: true

module Integrations
  module Samsys
    module Data 
      class MachineActivities
        def initialize(machine_id:)
          @formated_data = nil
          @machine_id = machine_id
          @stopped_on = Time.now.strftime("%FT%TZ")
          @started_on = (Time.now - 250.days).strftime("%FT%TZ")
        end
        
        def result
          @formated_data ||= call_api
        end

        def format_data(list)
          list.map do |field|
            field.filter{ |k, v| desired_fields.include?(k) }
          end
        end

        private 

        def call_api
          ::Samsys::SamsysIntegration.fetch_activities_machine(@machine_id, @started_on, @stopped_on).execute do |c|
            c.success do |list|
              format_data(list)
            end
          end
        end

        def desired_fields
          [:id, :start_date, :end_date, :road, :type, :sleep_count, :duration, :sleep_duration, :area_without_overlap, :area_with_overlap, :area_smart, :gasoline]
        end

      end
    end
  end
end
      