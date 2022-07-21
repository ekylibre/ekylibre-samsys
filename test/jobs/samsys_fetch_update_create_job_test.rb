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
    assert_equal(2, ride_set.rides.count)
    assert_equal(474, Crumb.where(ride_id: ride_set.rides.pluck(:id)).count)  
  end 
end

