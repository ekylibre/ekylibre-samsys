require 'test_helper'
require_relative '../../../test_helper'

class DataCountersTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette('auth') do
      Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
    end
  end

  def test_data_counters
    VCR.use_cassette('get_counters') do
      data = ::Samsys::Data::Counters.new.result
      assert %i[id v_bat v_ext owner association].all? { |s| data.first.key? s }, 'Should have correct attributes'
    end
  end
end
