# frozen_string_literal: true

require 'test_helper'
require 'securerandom'

# This class tests a "dummy" controller for authentication.
# Since testing Dummy controllers became quite complicated with
# ActionDispatch::IntegrationTest, it is testing the Profiles controller
# instead for the time being
class MetadataTest < ActionDispatch::IntegrationTest
  def authenticate
    ProfilesController.any_instance.expects(:authenticate_user)
    User.current = users(:test)
  end

  test 'meta adds total and search to JSON response' do
    authenticate
    search_query = 'name=profile1'
    get profiles_url, params: { search: search_query }
    assert_response :success
    assert_equal Profile.search_for(search_query).count,
                 json_body['meta']['total']
    assert_equal search_query, json_body['meta']['search']
  end

  context 'pagination' do
    setup do
      authenticate
    end

    should 'return correct pagination links' do
      3.times do
        Profile.create(ref_id: SecureRandom.uuid, name: SecureRandom.uuid)
      end
      get profiles_url, params: { limit: 1, offset: 3 }
      assert_response :success
      assert_match(/limit=1/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=1/, json_body['links']['previous'])
      assert_match(/offset=2/, json_body['links']['previous'])
      assert_match(/limit=1/, json_body['links']['next'])
      assert_match(/offset=4/, json_body['links']['next'])
      assert_match(/limit=1/, json_body['links']['last'])
      assert_match(/offset=#{Profile.count}/, json_body['links']['last'])
    end

    should 'return correct pagination links when there are two pages' do
      get profiles_url, params: { limit: 1, offset: 1 }
      assert_response :success
      assert_match(/limit=1/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=1/, json_body['links']['previous'])
      assert_match(/offset=1/, json_body['links']['previous'])
      assert_match(/limit=1/, json_body['links']['next'])
      assert_match(/offset=2/, json_body['links']['next'])
      assert_match(/limit=1/, json_body['links']['last'])
      assert_match(/offset=#{Profile.count}/, json_body['links']['last'])
    end

    should 'return correct pagination links when there is one page' do
      get profiles_url, params: { limit: Profile.count, offset: 1 }
      assert_response :success
      assert_match(/limit=#{Profile.count}/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=#{Profile.count}/, json_body['links']['previous'])
      assert_match(/offset=1/, json_body['links']['previous'])
      assert_match(/limit=#{Profile.count}/, json_body['links']['next'])
      assert_match(/offset=1/, json_body['links']['next'])
      assert_match(/limit=#{Profile.count}/, json_body['links']['last'])
      assert_match(/offset=1/, json_body['links']['last'])
    end

    should 'return correct pagination links when there are three pages' do
      Profile.create(ref_id: SecureRandom.uuid, name: SecureRandom.uuid)
      get profiles_url, params: { limit: 1, offset: 2 }
      assert_response :success
      assert_match(/limit=1/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=1/, json_body['links']['previous'])
      assert_match(/offset=1/, json_body['links']['previous'])
      assert_match(/limit=1/, json_body['links']['next'])
      assert_match(/offset=3/, json_body['links']['next'])
      assert_match(/limit=1/, json_body['links']['last'])
      assert_match(/offset=#{Profile.count}/, json_body['links']['last'])
    end
  end
end
