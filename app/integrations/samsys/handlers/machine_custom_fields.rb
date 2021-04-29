# frozen_string_literal: true

module Integrations
  module Samsys
    module Handlers
      class MachineCustomFields
        def initialize(machine_custom_fields:)
          @machine_custom_fields = machine_custom_fields
        end

        def bulk_find_or_create
          @machine_custom_fields.each do |key, value|
            unless cf = CustomField.find_by_name(value[:name])
              create_custom_field_for_machine(value[:name], value[:customized_type], value[:options])
            end
          end
        end
  
        private 

        def create_custom_field_for_machine(name, customized_type, options = {})
          # create custom field
          cf = CustomField.create!(name: name, customized_type: customized_type,
                                          nature: options[:nature] || :text,
                                          column_name: options[:column_name])
          # create custom field choice if nature is choice
          if cf.choice? && options[:choices]
            options[:choices].each do |value, label|
              cf.choices.create!(name: label, value: value)
            end
          end
        end

      end
    end
  end
end
