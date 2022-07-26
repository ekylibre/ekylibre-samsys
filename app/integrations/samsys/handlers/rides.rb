# frozen_string_literal: true

module Samsys
  module Handlers
    class Rides
      def initialize(ride_sets: ::RideSet.of_provider_name('samsys_ride_set'), machine_equipment:)
        @ride_sets = ride_sets
        @machine_equipment = machine_equipment
      end

      def bulk_find_or_create
        ride_sets.each do |ride_set|
          ::Samsys::Data::MetaWorks.new(activity_id: ride_set.provider[:data]['id']).result.each do |meta_work|
            if (field_id = meta_work[:field])
              field = Samsys::Data::Fields.new(call: ::Samsys::SamsysIntegration.fetch_field(field_id)).result
            end
            Samsys::Handlers::Ride.new(meta_work: meta_work,
              ride_set: ride_set, 
              machine_equipment: machine_equipment, 
              field: field).bulk_find_or_create
          end
        end
      end

      private
        attr_reader :ride_sets, :machine_equipment
    end
  end
end
