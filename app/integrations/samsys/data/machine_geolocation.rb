# frozen_string_literal: true

module Integrations
  module Samsys
    module Data 
      class MachineGeolocation
        def initialize(machine_id:)
          @formated_data = nil
          @machine_id = machine_id
        end
        
        def result
          @formated_data ||= call_api
        end

        private 

        def call_api
          ::Samsys::SamsysIntegration.fetch_geolocation(@machine_id).execute do |c|
            c.success do |geolocation|
              geolocation
            end
          end
        end

      end
    end
  end
end
    