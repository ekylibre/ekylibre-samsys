# frozen_string_literal: true

module Samsys
  module Data
    class Fields

      def result
        @formated_data ||= call_api
      end

      private

        def call_api
          ::Samsys::SamsysIntegration.fetch_fields.execute do |c|
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
          %w[id type geometry provider]
        end

    end
  end
end
