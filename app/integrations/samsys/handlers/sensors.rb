# frozen_string_literal: true

module Samsys
  module Handlers
    class Sensors
      def initialize(vendor:)
        @vendor = vendor
      end

      def bulk_find_or_create
        ::Samsys::Data::Counters.new.result.each do |counter|

          sensor = Sensor.find_or_create_by(
            vendor_euid: :samsys,
            model_euid: :samsys,
            euid: counter[:id],
            name: counter[:id],
            retrieval_mode: :integration
          )

          sensor.update!(
            battery_level: counter[:v_bat],
            last_transmission_at: Time.now
          )
  
          sensor_equipment = find_or_create_sensor_equipment(sensor, counter)
          
          # link the equipment to sensor
          sensor.update!(product_id: sensor_equipment.id) if sensor_equipment
        end
      end

      private 

      def find_or_create_sensor_equipment(sensor, counter)
        sensor_equipment = Equipment.of_provider_vendor(@vendor).of_provider_data(:id, counter[:id].to_s).first

        if sensor_equipment.present?
          sensor_equipment
        else
          create_sensor_equipment(sensor, counter)
        end            
      end

      def create_sensor_equipment(sensor, counter)
        owner = if counter[:owner][:type_cluster] == "farm"
                  Entity.of_company
                elsif counter[:owner][:type_cluster] != "farm"
                  #TODO create the entity
                end

        sensor_variant = ProductNatureVariant.import_from_nomenclature(:geolocation_box)

        sensor_equipment = Equipment.create!(
          variant_id: sensor_variant.id,
          name: counter[:id],
          initial_born_at: sensor.created_at,
          initial_population: 1,
          initial_owner: owner,
          work_number: "SAMSYS_#{counter[:id]}",
          provider: { vendor: @vendor, name: "samsys_sensor", data: { id: counter[:id] } }
        )
      end

    end
  end
end

