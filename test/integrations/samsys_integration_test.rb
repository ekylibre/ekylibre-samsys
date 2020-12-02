require 'test_helper'
require_relative '../test_helper'

class SamsysIntegrationTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette("auth") do
      Integration.create(nature: 'samsys', parameters: { email: '#', password: '#' })
    end
  end

  def test_get_counters
    VCR.use_cassette("get_counters") do
      Samsys::SamsysIntegration.fetch_all_counters.execute do |call|
        call.success do |response|
          assert_equal Hash, response.first.class, 'Should return an array of hash counter'
          assert %i[id v_bat].all? { |s| response.first.key? s }, 'Should have correct attributes'
        end
      end
    end
  end

  def test_get_all_machines
    VCR.use_cassette("get_machines") do
      Samsys::SamsysIntegration.fetch_all_machines.execute do |call|
        call.success do |response|
        end
      end
    end
  end

  def test_fetch_activities_machine
    VCR.use_cassette("get_machine_activities") do
      Samsys::SamsysIntegration.fetch_activities_machine("5e78eb21e440bbd47cada798").execute do |call|
        call.success do |response|
        end
      end
    end
  end
end
