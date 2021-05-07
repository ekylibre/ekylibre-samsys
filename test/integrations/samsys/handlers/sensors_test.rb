require 'test_helper'
require_relative '../../../test_helper'

class HandlersSensorsTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette("auth") do
      Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
    end
  end

  def test_find_or_create_sensor
    VCR.use_cassette("get_counters") do
      sensors = ::Samsys::Handlers::Sensors.new(vendor: 'samsys')
      new_ekylibre_sensors = sensors.bulk_find_or_create
      assert_equal new_ekylibre_sensors.last[:id], Sensor.last.euid, 'Should create a sensor'
      assert_equal Sensor.last.product, Equipment.last, 'Should create a sensor equipment'
    end
  end
end
