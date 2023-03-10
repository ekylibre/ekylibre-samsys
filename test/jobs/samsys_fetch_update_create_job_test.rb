require 'test_helper'
require_relative '../test_helper'

class SamsysFetchUpdateCreateJobTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    # dates to match only one ride set of testsynchroequipementsamsys3@gmail.com account
    @started_on = Time.new(2022, 7, 6, 13, 3, 0)
    @stopped_on = Time.new(2022, 7, 6, 13, 10, 0)
    @user = User.first
    shape = '{"type":"MultiPolygon","coordinates":[[[[-0.076277,44.623439],[-0.076279,44.623438],[-0.07629,44.623451],[-0.076494,44.623694],[-0.076625,44.623851],[-0.076633,44.62386],[-0.076631,44.623861],[-0.076236,44.62403],[-0.076232,44.624032],[-0.076449,44.624277],[-0.076553,44.624394],[-0.076538,44.624401],[-0.076516,44.624411],[-0.076356,44.62448],[-0.075674,44.624747],[-0.076659,44.625587],[-0.076651,44.625627],[-0.076649,44.625628],[-0.076632,44.625636],[-0.076639,44.625662],[-0.076604,44.625689],[-0.075118,44.626375],[-0.075059,44.626331],[-0.074595,44.625987],[-0.074369,44.625832],[-0.074165,44.625731],[-0.073735,44.625667],[-0.074406,44.625399],[-0.074281,44.625277],[-0.073887,44.624877],[-0.074304,44.624708],[-0.075309,44.624293],[-0.07523,44.624216],[-0.075016,44.624008],[-0.075508,44.623784],[-0.076203,44.623472],[-0.076277,44.623439]]]]}'
    @cultivable_zone = FactoryBot.create(:cultivable_zone, shape: Charta.new_geometry(JSON.parse(shape)))
    Preference.set!(:language, 'fra')
    Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
  end

  test 'Create the right number of records' do
    SamsysFetchUpdateCreateJob.perform_now(started_on: @started_on, stopped_on: @stopped_on, user_id: @user.id)
    assert_equal(1, RideSet.between(@started_on - 1.minute, @stopped_on).count)
    ride_set = RideSet.between(@started_on - 1.minute, @stopped_on).first

    # rides_set
    assert_equal(265, ride_set.shape.area.to_i)
    assert_equal('2022-07-06 11:02:02 UTC', ride_set.started_at.to_s)
    assert_equal('2022-07-06 11:10:09 UTC', ride_set.stopped_at.to_s)
    assert_equal(0.63e-2, ride_set.road)
    assert_equal('work', ride_set.nature)
    assert_equal(1, ride_set.sleep_count)
    assert_equal('RS000000000001', ride_set.number)
    assert_equal('PT5M51S', ride_set[:sleep_duration])
    assert_equal('PT8M7S', ride_set[:duration])
    assert_equal(0, ride_set.area_without_overlap)
    assert_equal(0, ride_set.area_with_overlap)
    assert_equal(0, ride_set.area_smart)
    assert_equal(0, ride_set.gasoline)
    assert_equal('62d907d0728c9ceb90ed31ef', ride_set.provider_data[:id])
    assert_equal('samsys_ride_set', ride_set.provider_name)
    assert_equal('samsys', ride_set.provider_vendor)
    assert_equal('Gyrobroyeur', ride_set.equipments.of_nature('main').first.name )

    assert_equal(2, ride_set.rides.count)
    road_ride = ride_set.rides.with_nature(:road).first
    work_ride = ride_set.rides.with_nature(:work).first

    assert_equal('R000000000002', road_ride.number)
    assert_equal('2022-07-06 11:10:03 UTC', road_ride.started_at.to_s)
    assert_equal('2022-07-06 11:10:09 UTC', road_ride.stopped_at.to_s)
    assert_equal(0, road_ride.sleep_count)
    assert_equal('62d907bb728c9ceb90ed31dc', road_ride.provider_data[:id])
    assert_equal(2.0, road_ride.provider_data[:machine_equipment_tool_width])
    assert_equal('samsys_ride', road_ride.provider_name)
    assert_equal('samsys', road_ride.provider_vendor)
    assert_equal('unaffected', road_ride.state )
    # assert_equal(890, road_ride.product_id)
    assert_equal('PT6S', road_ride[:duration])
    assert_equal('PT0S', road_ride[:sleep_duration])
    assert_equal(0.006285547045648425, road_ride.distance_km)
    assert_nil(road_ride.area_without_overlap)
    assert_nil(road_ride.area_with_overlap)
    assert_nil(road_ride.area_smart)
    assert_equal(0.0, road_ride.gasoline)
    assert_equal('road', road_ride.nature)
    assert_equal(ride_set.id, road_ride.ride_set_id)
    assert_nil(road_ride.intervention_id)
    assert_equal(6.690714031373384, road_ride.shape.length)

    assert_equal('R000000000001', work_ride.number)
    assert_equal('2022-07-06 11:02:02 UTC', work_ride.started_at.to_s)
    assert_equal('2022-07-06 11:10:03 UTC', work_ride.stopped_at.to_s)
    assert_equal(1, work_ride.sleep_count)
    assert_equal('62d907bb728c9ceb90ed31db', work_ride.provider_data[:id])
    assert_equal(2.0, work_ride.provider_data[:machine_equipment_tool_width])
    assert_equal('samsys_ride', work_ride.provider_name)
    assert_equal('samsys', work_ride.provider_vendor)
    assert_equal('unaffected', work_ride.state )
    # assert_equal(890, work_ride.product_id)
    assert_equal('PT8M', work_ride[:duration])
    assert_equal('PT5M51S', work_ride[:sleep_duration])
    assert_equal(0.11312596855435088, work_ride.distance_km)
    assert_equal(0, work_ride.area_without_overlap)
    assert_equal(0, work_ride.area_with_overlap)
    assert_equal(0, work_ride.area_smart)
    assert_equal(0, work_ride.gasoline)
    assert_equal('work', work_ride.nature)
    assert_equal(ride_set.id, work_ride.ride_set_id)
    assert_nil(work_ride.intervention_id)
    assert_equal(136.04382546452223, work_ride.shape.length)
    assert_equal(@cultivable_zone, work_ride.cultivable_zone)

    assert_equal(474, Crumb.where(ride_id: ride_set.rides.pluck(:id)).count)

    pause_crumb = work_ride.crumbs.where(nature: :pause).first
    assert_equal('pause', pause_crumb.nature)
    assert_equal('samsys', pause_crumb.device_uid)
    assert_equal(4, pause_crumb.accuracy)
    assert_equal('2022-07-06 11:02:13 UTC', pause_crumb.read_at.to_s)
    assert_equal(351.76, pause_crumb.metadata['duration'])
    assert_equal('2022-07-06T11:02:13.600000Z', pause_crumb.metadata['start_date'])
    assert_equal('2022-07-06T11:08:05.360000Z', pause_crumb.metadata['end_date'])
    assert_equal(work_ride.id, pause_crumb.ride_id)
    assert_equal('samsys', pause_crumb.provider[:vendor])
    assert_equal('samsys_crumb_break', pause_crumb.provider[:name])
    assert_equal('2022-07-06T11:02:13.600000Z', pause_crumb.provider_data[:start_date])

    assert_equal(1, work_ride.crumbs.where(nature: :hard_start).count)
    start_crumb = work_ride.crumbs.where(nature: :hard_start).first
    assert_equal('samsys', start_crumb.device_uid)
    assert_equal(4, start_crumb.accuracy)
    assert_equal('2022-07-06 11:02:02 UTC', start_crumb.read_at.to_s)
    assert_equal({}, start_crumb.metadata)
    assert_equal(work_ride.id, start_crumb.ride_id)
    assert_equal('samsys', start_crumb.provider[:vendor])
    assert_equal('samsys_crumb', start_crumb.provider[:name])
    assert_equal('62c56bb9e04c9b34a9725358', start_crumb.provider_data[:id])
    assert_equal(3.4, start_crumb.provider_data[:speed])

    assert_equal(1, work_ride.crumbs.where(nature: :hard_stop).count)
  end
end
