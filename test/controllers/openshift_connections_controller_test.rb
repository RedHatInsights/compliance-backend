# frozen_string_literal: true

require 'test_helper'

class OpenshiftConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OpenshiftConnectionsController.any_instance.expects(:authenticate_user)
    User.stubs(:current).returns(users(:test))
    @oc = mock('openshift connection')
  end

  test 'create failure' do
    OpenshiftConnection.expects(:new).returns(@oc)
    @oc.expects(:save)
    post openshift_connections_path, params: {
      openshift_connection: {
        username: 'test_user'
      }
    }

    assert_response :unprocessable_entity
  end

  test 'create success' do
    OpenshiftConnection.expects(:new).returns(@oc)
    @oc.expects(:save).returns(true)
    post openshift_connections_path, params: {
      openshift_connection: {
        username: 'test_user'
      }
    }

    assert_response :success
  end
end
