require 'test_helper'
require_relative '../test_helper'

class SamsysFetchUpdateCreateJobTest < ActiveJob::TestCase
  setup do
    #dates to match only one ride set of testsynchroequipementsamsys3@gmail.com account
    @started_on = Time.new(2022,7,6,13,3,0)
    @stopped_on = Time.new(2022,7,6,13,10,0)
    @user = User.first
    Preference.set!(:language, 'fra')
    Integration.create(nature: 'samsys', parameters: { email: ENV['SAMSYS_TEST_EMAIL'], password: ENV['SAMSYS_TEST_PASSWORD'] })
  end

  test 'Create the right number of records' do
    SamsysFetchUpdateCreateJob.perform_now(started_on: @started_on, stopped_on:@stopped_on, user_id: @user)
    assert_equal(1, RideSet.between(@started_on - 1.minute, @stopped_on).count)
    ride_set = RideSet.between(@started_on - 1.minute, @stopped_on).first

    #rides_set
    assert_equal(265, ride_set.shape.area.to_i)
    assert_equal("2022-07-06 11:02:02 UTC", ride_set.started_at.to_s)
    assert_equal("2022-07-06 11:10:09 UTC", ride_set.stopped_at.to_s)
    assert_equal(0.63e-2, ride_set.road)
    assert_equal('work',ride_set.nature)
    assert_equal(1, ride_set.sleep_count)
    assert_equal("RS000000000001",ride_set.number)
    assert_equal("PT5M51S", ride_set[:sleep_duration])
    assert_equal("PT8M7S", ride_set[:duration])
    assert_equal(0, ride_set.area_without_overlap)
    assert_equal(0, ride_set.area_with_overlap)
    assert_equal(0, ride_set.area_smart)
    assert_equal(0, ride_set.gasoline)
    assert_equal("62d907d0728c9ceb90ed31ef", ride_set.provider_data[:id])
    assert_equal("samsys_ride_set", ride_set.provider_name)
    assert_equal("samsys", ride_set.provider_vendor)

    assert_equal(2, ride_set.rides.count)
    road_ride = ride_set.rides.with_nature(:road).first
    work_ride = ride_set.rides.with_nature(:work).first

    assert_equal("R000000000002", road_ride.number)
    assert_equal("2022-07-06 11:10:03 UTC", road_ride.started_at.to_s)
    assert_equal("2022-07-06 11:10:09 UTC", road_ride.stopped_at.to_s)
    assert_equal(0, road_ride.sleep_count)
    assert_equal("Gyrobroyeur", road_ride.equipment_name )
    assert_equal("62d907bb728c9ceb90ed31dc", road_ride.provider_data[:id])
    assert_equal(2.0, road_ride.provider_data[:machine_equipment_tool_width])
    assert_equal("samsys_ride", road_ride.provider_name)
    assert_equal("samsys", road_ride.provider_vendor)
    assert_equal("unaffected", road_ride.state )
    #assert_equal(890, road_ride.product_id)
    assert_equal("PT6S",road_ride[:duration])
    assert_equal("PT0S",road_ride[:sleep_duration])
    assert_equal(0.006285547045648425, road_ride.distance_km)
    assert_equal(nil,road_ride.area_without_overlap)
    assert_equal(nil,road_ride.area_with_overlap)
    assert_equal(nil,road_ride.area_smart)
    assert_equal(0.0,road_ride.gasoline)
    assert_equal("road",road_ride.nature)
    assert_equal(ride_set.id, road_ride.ride_set_id)
    assert_equal(nil,road_ride.intervention_id)
    assert_equal(6.690714031373384, road_ride.shape.length)

    assert_equal("R000000000001", work_ride.number)
    assert_equal("2022-07-06 11:02:02 UTC", work_ride.started_at.to_s)
    assert_equal("2022-07-06 11:10:03 UTC", work_ride.stopped_at.to_s)
    assert_equal(1, work_ride.sleep_count)
    assert_equal("Gyrobroyeur", work_ride.equipment_name )
    assert_equal("62d907bb728c9ceb90ed31db", work_ride.provider_data[:id])
    assert_equal(2.0, work_ride.provider_data[:machine_equipment_tool_width])
    assert_equal("samsys_ride", work_ride.provider_name)
    assert_equal("samsys", work_ride.provider_vendor)
    assert_equal("unaffected", work_ride.state )
    #assert_equal(890, work_ride.product_id)
    assert_equal("PT8M",work_ride[:duration])
    assert_equal("PT5M51S",work_ride[:sleep_duration])
    assert_equal(0.11312596855435088, work_ride.distance_km)
    assert_equal(0,work_ride.area_without_overlap)
    assert_equal(0,work_ride.area_with_overlap)
    assert_equal(0,work_ride.area_smart)
    assert_equal(0,work_ride.gasoline)
    assert_equal("work",work_ride.nature)
    assert_equal(ride_set.id, work_ride.ride_set_id)
    assert_equal(nil,work_ride.intervention_id)
    assert_equal(136.04382546452223, work_ride.shape.length)
  
    assert_equal(474, Crumb.where(ride_id: ride_set.rides.pluck(:id)).count)

    pause_crumb = work_ride.crumbs.where(nature: :pause).first
    assert_equal('pause', pause_crumb.nature)
    assert_equal('samsys', pause_crumb.device_uid)
    assert_equal(4, pause_crumb.accuracy)
    assert_equal("2022-07-06 11:02:13 UTC", pause_crumb.read_at.to_s)
    assert_equal(351.76, pause_crumb.metadata['duration'])
    assert_equal("2022-07-06T11:02:13.600000Z", pause_crumb.metadata['start_date'])
    assert_equal("2022-07-06T11:08:05.360000Z", pause_crumb.metadata['end_date'])
    assert_equal(work_ride.id, pause_crumb.ride_id)
    assert_equal("samsys", pause_crumb.provider[:vendor])
    assert_equal("samsys_crumb_break", pause_crumb.provider[:name])
    assert_equal("2022-07-06T11:02:13.600000Z", pause_crumb.provider_data[:start_date])

    assert_equal(1, work_ride.crumbs.where(nature: :hard_start).count)
    start_crumb = work_ride.crumbs.where(nature: :hard_start).first
    assert_equal('samsys', start_crumb.device_uid)
    assert_equal(4, start_crumb.accuracy)
    assert_equal("2022-07-06 11:02:02 UTC", start_crumb.read_at.to_s)
    assert_equal({}, start_crumb.metadata)
    assert_equal(work_ride.id, start_crumb.ride_id)
    assert_equal("samsys", start_crumb.provider[:vendor])
    assert_equal("samsys_crumb", start_crumb.provider[:name])
    assert_equal("62c56bb9e04c9b34a9725358", start_crumb.provider_data[:id])
    assert_equal(3.4, start_crumb.provider_data[:speed])

    assert_equal(1, work_ride.crumbs.where(nature: :hard_stop).count)
  end 
end

