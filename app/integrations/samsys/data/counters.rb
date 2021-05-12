# frozen_string_literal: true

module Integrations
  module Samsys
    module Data 
      class Counters
        def result
          @formated_data ||= call_api
        end

        private 

        def call_api
          ::Samsys::SamsysIntegration.fetch_all_counters.execute do |c|
            c.success do |list|
              list
            end
          end
        end

      end
    end
  end
end
  