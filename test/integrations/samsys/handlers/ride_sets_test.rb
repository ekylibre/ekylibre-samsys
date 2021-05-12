require 'test_helper'
require_relative '../../../test_helper'

class HandlersRideSetsTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette("auth") do
      Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
    end
  end

  def test_find_or_create_ride_set
    VCR.use_cassette("get_machines", :record => :new_episodes) do
      machine_custom_fields = ::Samsys::Handlers::MachineCustomFields.new
      machine_custom_fields.bulk_find_or_create

      stopped_on = Time.now
      ride_sets = ::Samsys::Handlers::RideSets.new(stopped_on: stopped_on)
      ride_sets.bulk_find_or_create

      assert_equal Ride.last.equipment, Equipment.last, "Must create machine equipment"
      assert_equal RideSet.present?, true, 'Must create RideSet'
      assert_equal Ride.present?, true, 'Must create Ride'
      assert_equal Crumb.present?, true, 'Must create Crumb'
    end
  end
end
