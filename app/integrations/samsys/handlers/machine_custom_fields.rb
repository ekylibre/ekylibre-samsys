# frozen_string_literal: true

module Samsys
  module Handlers
    class MachineCustomFields

      MACHINE_CUSTOM_FIELDS = {
        'model' => { name: 'Modèle', customized_type: 'Equipment', options: { column_name: 'mod_name' } },
        'brand' => { name: 'Marque', customized_type: 'Equipment', options: { column_name: 'brand_name' } }
      }.freeze

      def bulk_find_or_create
        MACHINE_CUSTOM_FIELDS.each do |_key, value|
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
