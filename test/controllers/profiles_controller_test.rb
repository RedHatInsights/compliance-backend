# frozen_string_literal: true

require 'test_helper'

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    ProfilesController.any_instance.stubs(:authenticate_user)
    @relation = mock('relation')
  end

  test 'index lists all profiles' do
    @relation.expects(:paginate).returns(@relation)
    @relation.expects(:sort_by).returns(@relation)
    ProfileSerializer.expects(:new)
    ProfilesController.any_instance.expects(:policy_scope).returns(@relation)
    get profiles_url

    assert_response :success
  end

  test 'index filters by hostname' do
    @relation.expects(:paginate).returns(@relation)
    @relation.expects(:sort_by).returns(@relation)
    ProfileSerializer.expects(:new)
    ProfilesController.any_instance.expects(:policy_scope).returns(@relation)
    Profile.expects(:includes).returns(@relation)
    @relation.expects(:where).with(hosts: { name: 'foo' }).returns(@relation)
    @relation.expects(:includes).with(:profile_hosts).returns(@relation)
    get profiles_url(hostname: 'foo')

    assert_response :success
  end

  test 'show' do
    ProfilesController.any_instance.expects(:authorize)
    Profile.expects(:friendly).returns(@relation)
    @relation.expects(:find).with('1')
    get profile_url(1)

    assert_response :success
  end
end
