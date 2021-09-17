require 'test_helper'
require_relative '../../../test_helper'

class DataMachinesTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette('auth') do
      Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
    end
  end

  def test_data_machines
    VCR.use_cassette('get_machines') do
      data = ::Samsys::Data::Machines.new.result
      assert %i[id name machine_type cluster brand tool_width associations provider].all? { |s|
 data.first.key? s }, 'Should have correct attributes'
    end
  end
end
