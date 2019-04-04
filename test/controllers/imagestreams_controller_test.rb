# frozen_string_literal: true

require 'test_helper'

class ImagestreamsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    ImagestreamsController.any_instance.expects(:authenticate_user)
    User.current = users(:test)
    User.current.account = accounts(:test)
  end

  test 'create saves openshift connection and triggers job' do
    assert_difference('OpenshiftConnection.count', 1) do
      assert_difference('Imagestream.count', 1) do
        assert_enqueued_jobs 1 do
          post imagestreams_url, params: creation_params
        end
      end
    end
    assert_response :success
  end

  test 'if openshift_connection params were not correct, do not save' do
    assert_difference('OpenshiftConnection.count', 0) do
      assert_difference('Imagestream.count', 0) do
        assert_enqueued_jobs 0 do
          post imagestreams_url,
               params: creation_params.except(:openshift_connection)
        end
      end
    end
    assert_response :unprocessable_entity
  end

  test 'if imagestream params were not correct, do not save' do
    assert_difference('OpenshiftConnection.count', 1) do
      assert_difference('Imagestream.count', 0) do
        assert_enqueued_jobs 0 do
          post imagestreams_url,
               params: creation_params.except(:imagestream)
        end
      end
    end
    assert_response :unprocessable_entity
  end

  def creation_params
    {
      policy: { standard: true },
      imagestream: { name: 'namespace/imagename' },
      openshift_connection: {
        username: 'userfoo',
        token: 'tokenbar',
        api_url: 'https://console.insights-dev.openshift.com/oapi',
        registry_api_url: 'registry.insights-dev.openshift.com:443'
      }
    }
  end
end
