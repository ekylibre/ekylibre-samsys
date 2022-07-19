require 'test_helper'
require_relative '../../../test_helper'

class HandlersRideSetsTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette('auth') do
      Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
    end
  end

  def test_find_or_create_ride_set
    VCR.use_cassette('get_machines') do
      machine_custom_fields = ::Samsys::Handlers::MachineCustomFields.new
      machine_custom_fields.bulk_find_or_create

      started_on = Time.now
      stopped_on = Time.now + 1*60*60
      assert_difference 'RideSet.count', 3 do
        ::Samsys::Handlers::RideSets.new(started_on: started_on, stopped_on: stopped_on).bulk_find_or_create
      end
    end

  end
end
