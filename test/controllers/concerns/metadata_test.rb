# frozen_string_literal: true

require 'test_helper'
require 'securerandom'

# This class tests a "dummy" controller for authentication.
# Since testing Dummy controllers became quite complicated with
# ActionDispatch::IntegrationTest, it is testing the Profiles controller
# instead for the time being
class MetadataTest < ActionDispatch::IntegrationTest
  setup { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ) }
  def authenticate
    V1::ProfilesController.any_instance.expects(:authenticate_user).yields
    User.current = FactoryBot.create(:user)
  end

  test 'meta adds tags to the links' do
    V1::SystemsController.any_instance.expects(:authenticate_user).yields
    User.current = FactoryBot.create(:user)

    get [
      systems_url,
      'tags=foo/bar=baz&tags=foo/bar=yay'
    ].join('?')

    assert_response :success
    re = /tags=foo%2Fbar%3Dbaz&tags=foo%2Fbar%3Dyay/
    assert_match(re, json_body['links']['first'])
    assert_match(re, json_body['links']['last'])
  end

  test 'meta adds includes to JSON response' do
    authenticate
    3.times do
      FactoryBot.create(:profile)
    end
    get profiles_url, params: { include: 'rules', limit: 1, offset: 2,
                                search: '' }
    assert_response :success
    assert_match(/include=rules/, json_body['links']['first'])
    assert_match(/include=rules/, json_body['links']['last'])
    assert_match(/include=rules/, json_body['links']['next'])
    assert_match(/include=rules/, json_body['links']['previous'])
    assert json_body.dig('included')
  end

  test 'meta adds total and search to JSON response' do
    authenticate
    3.times do
      FactoryBot.create(:profile)
    end

    FactoryBot.create(:profile)

    search_query = 'ref_id~xccdf_org.ssgproject.content_profile_'
    get profiles_url, params: { search: search_query, limit: 1, offset: 2 }
    assert_response :success
    assert_match(/search=ref_id~xccdf_org.ssgproject.content_profile_/,
                 json_body['links']['first'])
    assert_match(/search=ref_id~xccdf_org.ssgproject.content_profile_/,
                 json_body['links']['last'])
    assert_match(/search=ref_id~xccdf_org.ssgproject.content_profile_/,
                 json_body['links']['next'])
    assert_match(/search=ref_id~xccdf_org.ssgproject.content_profile_/,
                 json_body['links']['previous'])
    assert_equal Profile.search_for(search_query).count,
                 json_body['meta']['total']
    assert_equal search_query, json_body['meta']['search']
  end

  test 'meta adds sort_by to JSON response' do
    authenticate
    3.times do
      FactoryBot.create(:profile)
    end

    get profiles_url, params: { sort_by: ['name'], limit: 1, offset: 2 }
    assert_response :success
    assert_match(/sort_by%5B%5D=name/, json_body['links']['first'])
    assert_match(/sort_by%5B%5D=name/, json_body['links']['last'])
    assert_match(/sort_by%5B%5D=name/, json_body['links']['next'])
    assert_match(/sort_by%5B%5D=name/, json_body['links']['previous'])
    assert_equal ['name'], json_body['meta']['sort_by']
  end

  test 'meta escapes parameter values in links' do
    authenticate
    3.times do
      FactoryBot.create(:profile)
    end

    search_query = "name != ''"
    get profiles_url, params: { search: search_query, limit: 1, offset: 2 }
    assert_response :success
    assert_includes json_body['links']['first'], 'search=name+%21%3D+%27%27'
    assert_includes json_body['links']['last'], 'search=name+%21%3D+%27%27'
    assert_includes json_body['links']['next'], 'search=name+%21%3D+%27%27'
    assert_includes json_body['links']['previous'], 'search=name+%21%3D+%27%27'
  end

  test 'meta adds relationships param to JSON response' do
    authenticate
    3.times do
      FactoryBot.create(:profile)
    end

    get profiles_url, params: { relationships: false, limit: 1, offset: 2 }
    assert_response :success
    assert_includes json_body['links']['first'], 'relationships=false'
    assert_includes json_body['links']['last'], 'relationships=false'
    assert_includes json_body['links']['next'], 'relationships=false'
    assert_includes json_body['links']['previous'], 'relationships=false'
    assert_equal({}, parsed_data[0]['relationships'])
    assert_equal false, json_body['meta']['relationships']
  end

  context 'pagination' do
    setup do
      authenticate
      @parent = FactoryBot.create(:canonical_profile)
      2.times do
        FactoryBot.create(:profile, parent_profile: @parent)
      end
    end

    should 'return correct pagination links' do
      3.times do
        FactoryBot.create(:profile, parent_profile: @parent)
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
      assert_match(/offset=#{Profile.canonical(false).count}/,
                   json_body['links']['last'])
    end

    should 'return correct pagination links when there are two pages' do
      get profiles_url, params: { limit: 1, offset: 1 }
      assert_response :success
      assert_match(/limit=1/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=1/, json_body['links']['next'])
      assert_match(/offset=2/, json_body['links']['next'])
      assert_match(/limit=1/, json_body['links']['last'])
      assert_match(/offset=#{Profile.canonical(false).count}/,
                   json_body['links']['last'])
    end

    should 'return correct pagination links when there is one page' do
      get profiles_url, params: {
        limit: Profile.canonical(false).count, offset: 1
      }
      assert_response :success
      assert_match(/limit=#{Profile.canonical(false).count}/,
                   json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=#{Profile.canonical(false).count}/,
                   json_body['links']['last'])
      assert_match(/offset=1/, json_body['links']['last'])
    end

    should 'return correct pagination links when there are three pages' do
      FactoryBot.create(:profile, parent_profile: @parent)

      get profiles_url, params: { limit: 1, offset: 2 }
      assert_response :success
      assert_match(/limit=1/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/limit=1/, json_body['links']['previous'])
      assert_match(/offset=1/, json_body['links']['previous'])
      assert_match(/limit=1/, json_body['links']['next'])
      assert_match(/offset=3/, json_body['links']['next'])
      assert_match(/limit=1/, json_body['links']['last'])
      assert_match(/offset=#{Profile.canonical(false).count}/,
                   json_body['links']['last'])
    end

    should 'return correct pagination links with partially filled last page' do
      3.times do
        FactoryBot.create(:profile, parent_profile: @parent)
      end
      get profiles_url, params: { limit: 2, offset: 1 }
      assert_response :success
      assert_match(/limit=2/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
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

    should 'not include previous if on first page' do
      get profiles_url, params: { limit: 1, offset: 1 }
      assert_response :success
      assert_match(/limit=1/, json_body['links']['first'])
      assert_match(/offset=1/, json_body['links']['first'])
      assert_not json_body['links']['previous']
    end

    should 'not include next if on last page' do
      get profiles_url, params: { limit: 1, offset: 2 }
      assert_response :success
      assert_match(/limit=1/, json_body['links']['last'])
      assert_match(/offset=2/, json_body['links']['last'])
      assert_not json_body['links']['next']
    end

    should 'not return invalid previous link if passed wrong params' do
      get profiles_url, params: { limit: 1, offset: 93 }
      assert_response :success
      assert_equal(1, json_body['meta']['limit'])
      assert_equal(93, json_body['meta']['offset'])
      assert_not json_body['links']['previous']
      assert_match(/offset=1/, json_body['links']['first'])
      assert_match(/offset=#{Profile.canonical(false).count}/,
                   json_body['links']['last'])
    end

    should 'return invalid parameter if limit=0' do
      get profiles_url, params: { limit: 0 }
      assert_response 422
      assert_equal('Invalid parameter: limit must be greater than 0',
                   json_body['errors'][0])
    end

    should 'return invalid parameter if limit<0' do
      get profiles_url, params: { limit: -256 }
      assert_response 422
      assert_equal('Invalid parameter: limit must be greater than 0',
                   json_body['errors'][0])
    end

    should 'return invalid parameter if limit is float' do
      get profiles_url, params: { limit: 15.12 }
      assert_response 422
      assert_equal('Invalid parameter: limit must be an integer',
                   json_body['errors'][0])
    end

    should 'return invalid parameter if limit is string' do
      get profiles_url, params: { limit: '15.12' }
      assert_response 422
      assert_equal('Invalid parameter: limit must be an integer',
                   json_body['errors'][0])
    end

    should 'return invalid parameter if offset=0' do
      get profiles_url, params: { offset: 0 }
      assert_response 422
      assert_equal('Invalid parameter: offset must be greater than 0',
                   json_body['errors'][0])
    end

    should 'return invalid parameter if offset<0' do
      get profiles_url, params: { offset: -15 }
      assert_response 422
      assert_equal('Invalid parameter: offset must be greater than 0',
                   json_body['errors'][0])
    end

    should 'return invalid parameter if offset is float' do
      get profiles_url, params: { offset: 13.37 }
      assert_response 422
      assert_equal('Invalid parameter: offset must be an integer',
                   json_body['errors'][0])
    end

    should 'return invalid parameter if offset is string' do
      get profiles_url, params: { offset: '13.37' }
      assert_response 422
      assert_equal('Invalid parameter: offset must be an integer',
                   json_body['errors'][0])
    end
  end
end
