require 'test_helper'
require_relative '../../../test_helper'

class CountersTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette("auth") do
      Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
    end
  end

  def test_get_counters
    VCR.use_cassette("get_counters") do
      binding.pry
      data = ::Integrations::Samsys::Data::Counters.new.result
      binding.pry
    end
  end
end

