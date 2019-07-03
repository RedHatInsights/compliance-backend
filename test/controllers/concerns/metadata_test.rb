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
    users(:test).account = accounts(:test)
    User.current = users(:test)
  end

  test 'meta adds total and search to JSON response' do
    authenticate
    profiles(:one).update(account: accounts(:test))
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
      Profile.all.find_each { |p| p.update(account_id: accounts(:test).id) }
    end

    should 'return correct pagination links' do
      3.times do
        Profile.create(ref_id: SecureRandom.uuid, name: SecureRandom.uuid,
                       account: accounts(:test))
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
      Profile.create(ref_id: SecureRandom.uuid, name: SecureRandom.uuid,
                     account: accounts(:test))
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

    should 'return correct pagination links with partially filled last page' do
      3.times do
        Profile.create(ref_id: SecureRandom.uuid, name: SecureRandom.uuid,
                       account: accounts(:test))
      end
      get profiles_url, params: { limit: 2, offset: 1 }
      assert_response :success
      assert_match(/limit=2/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=2/, json_body['links']['previous'])
      assert_match(/offset=1/, json_body['links']['previous'])
      assert_match(/limit=2/, json_body['links']['next'])
      assert_match(/offset=2/, json_body['links']['next'])
      assert_match(/limit=2/, json_body['links']['last'])
      assert_match(/offset=#{(Profile.count / 2.0).ceil}/,
                   json_body['links']['last'])
    end

    should 'return passed limit and offset' do
      get profiles_url, params: { limit: 1, offset: 2 }
      assert_response :success
      assert_equal(1, json_body['meta']['limit'])
      assert_equal(2, json_body['meta']['offset'])
    end
  end
end
