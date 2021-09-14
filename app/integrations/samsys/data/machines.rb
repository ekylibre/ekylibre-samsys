# frozen_string_literal: true

module Samsys
  module Data
    class Machines
      def result
        @formated_data ||= call_api
      end

      private

        def call_api
          ::Samsys::SamsysIntegration.fetch_all_machines.execute do |c|
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
          %i[id name machine_type cluster brand tool_width associations provider]
        end

    end
  end
end
