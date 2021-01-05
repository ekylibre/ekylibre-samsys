require 'test_helper'
require_relative '../test_helper'

class SamsysIntegrationTest < ::Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    VCR.use_cassette("auth") do
      Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
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
          assert_equal Hash, response.first.class, 'Should return an array of hash machines'
        end
      end
    end
  end

  # Machine activities equal to Ride Set at Ekylibre
  def test_fetch_activities_machine
    started_on = ("2020-12-17".to_time - 90.days).strftime("%FT%TZ")
    stopped_on = "2020-12-17".to_time.strftime("%FT%TZ")

    VCR.use_cassette("get_machine_activities") do
      Samsys::SamsysIntegration.fetch_activities_machine("5f6b41a15fd2a1ddcb5386ea", started_on, stopped_on).execute do |call|
        call.success do |response|
          assert_equal Hash, response.first.class, 'Should return an array of hash activities'
          assert %w[id start_date end_date road type sleep_count duration sleep_duration area_without_overlap area_with_overlap area_smart gasoline].all? { |s| response.first.key? s }, 'Should have correct attributes'
        end
      end
    end
  end

  # Activity equal to Ride at Ekylibre
  def test_fetch_works_activity
    VCR.use_cassette("get_works_activity") do
      Samsys::SamsysIntegration.fetch_works_activity("5fa3ab62c493556ea4ec8bfd").execute do |call|
        call.success do |response|
          r = JSON.parse(response)
          assert_equal Hash, r.first.class, 'Should return an array of hash works'
          assert %w[id start_date end_date duration sleep_count sleep_duration type distance_km area_without_overlap area_with_overlap area_smart gasoline].all? { |s| r.first.key? s }, 'Should have correct attributes'
        end
      end
    end
  end

  # Work geolocation equal to crumb at Ekylibre
  def test_frech_work_geolocation
    VCR.use_cassette("get_work_geolocation") do
      Samsys::SamsysIntegration.fetch_work_geolocations("5fa3ab62c493556ea4ec8bfc").execute do |call| 
        call.success do |response|
          r = JSON.parse(response)
          assert_equal Hash, r.first.class, 'Should return an array of hash geolocations'
          assert %w[id_data properties geometry].all? { |s| r.first.key? s }, 'Should have correct attributes'
        end
      end
    end
  end
end
