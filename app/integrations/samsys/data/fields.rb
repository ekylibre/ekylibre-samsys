# frozen_string_literal: true

module Samsys
  module Data
    class Fields
      def initialize(call: ::Samsys::SamsysIntegration.fetch_fields)
        @call = call
      end

      def result
        @formated_data ||= call_api
      end

      private

        attr_reader :call

        def call_api
          call.execute do |c|
            c.success do |results|
              if results.is_a?(Array)
                results.map { |result| format_data(result) }
              else
                format_data(results)
              end
            end
          end
        end

        def format_data(field)
          field.filter{ |k, _v| desired_fields.include?(k) }
        end

        def desired_fields
          %w[id type geometry provider]
        end

    end
  end
end