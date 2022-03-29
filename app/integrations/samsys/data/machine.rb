# frozen_string_literal: true

module Samsys
  module Data
    class Machine

      def initialize(machine_id)
        @machine_id = machine_id
      end

      def get_machine
        fetch
      end

      def delete_machine
        delete
      end

      private

        def fetch
          ::Samsys::SamsysIntegration.get_machine(@machine_id).execute do |c|
            c.success do |list|
              format_data(list)
            end
          end
        end

        def delete
          ::Samsys::SamsysIntegration.delete_machine(@machine_id).execute do |c|
            c.success do |list|
              list
            end
          end
        end

        def format_data(list)
          list.filter{ |k, _v| desired_fields.include?(k) }
        end

        def desired_fields
          %i[id name start_date machine_type cluster brand model tool_width associations provider]
        end

    end
  end
end
