# frozen_string_literal: true

require 'test_helper'

class TestResultTest < ActiveSupport::TestCase
  should have_one(:benchmark).through(:profile)
  should have_many(:rule_results).dependent(:delete_all)
  should belong_to(:profile)
  should belong_to(:host)
  should validate_presence_of(:host)
  should validate_presence_of(:profile)
  should validate_presence_of(:end_time)
  should validate_uniqueness_of(:end_time).scoped_to(%i[host_id profile_id])

  test 'destroy associated external profiles if they have no test results' do
    profiles(:one).update!(hosts: [hosts(:one)], external: true,
                           account: accounts(:test))
    assert_equal test_results(:one).host, hosts(:one)
    assert_equal test_results(:one).profile, profiles(:one)
    assert profiles(:one).test_results.one?
    assert_nil profiles(:one).policy_object

    assert_difference('Profile.count', -1) { hosts(:one).destroy }
  end

  test 'does not destroy external policies if they still have hosts' do
    test_results(:two).update! host: hosts(:two), profile: profiles(:one)
    assert_equal test_results(:two).host, hosts(:two)
    assert_equal test_results(:two).profile, profiles(:one)
    assert_equal test_results(:one).host, hosts(:one)
    assert_equal test_results(:one).profile, profiles(:one)
    assert 2, profiles(:one).test_results.count
    assert_nil profiles(:one).policy_object
    assert_nil profiles(:two).policy_object

    assert_difference('Profile.count', 0) { hosts(:one).destroy }
  end
end
