# frozen_string_literal: true

module Samsys
  module Data 
    class Fields
      def initialize
        @formated_data = nil
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
        ::Samsys::SamsysIntegration.fetch_fields.execute do |c|
          c.success do |list|
            format_data(list)
          end
        end
      end

      def desired_fields
        ["id", "type", "geometry"]
      end

    end
  end
end
