# frozen_string_literal: true

require 'test_helper'

module V1
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      ProfilesController.any_instance.stubs(:authenticate_user)
      User.current = users(:test)
      users(:test).update! account: accounts(:test)
      profiles(:one).update! account: accounts(:test)
    end

    class TailoringFileTest < ProfilesControllerTest
      test 'tailoring_file with a canonical profile returns no content' do
        profiles(:one).update! rules: [rules(:one)]
        get tailoring_file_v1_profile_url(profiles(:one).id)
        assert_response :no_content
      end

      test 'tailoring_file with a noncanonical profile matching its parent'\
        'returns no content' do
        profiles(:two).update!(rules: [rules(:one)])
        profiles(:one).update!(parent_profile: profiles(:two),
                               rules: [rules(:one)])
        get tailoring_file_v1_profile_url(profiles(:one).id)
        assert_response :no_content
      end

      test 'tailoring_file with a noncanonical profile '\
        'returns tailoring file' do
        profiles(:two).update!(rules: [rules(:one), rules(:two)])
        profiles(:one).update!(parent_profile: profiles(:two),
                               rules: [rules(:one)])
        get tailoring_file_v1_profile_url(profiles(:one).id)
        assert_response :success
        assert_equal Mime[:xml].to_s, @response.content_type
      end
    end

    class IndexTest < ProfilesControllerTest
      test 'external profiles can be requested' do
        profiles(:one).update! external: true
        search_query = 'external=true'
        get v1_profiles_url, params: { search: search_query }
        assert_response :success

        profiles = JSON.parse(response.body)
        assert_equal 1, profiles['data'].length
        assert_equal profiles(:one).id, profiles['data'].first['id']
      end

      test 'canonical profiles can be requested' do
        profiles(:two).update! parent_profile_id: profiles(:one).id
        search_query = 'canonical=true'
        get v1_profiles_url, params: { search: search_query }
        assert_response :success

        profiles = JSON.parse(response.body)
        assert_equal 1, profiles['data'].length
        assert_equal profiles(:one).id, profiles['data'].first['id']
      end

      test 'does not contain external or canonical profiles by default' do
        get v1_profiles_url
        assert_response :success

        profiles = JSON.parse(response.body)
        assert_empty profiles['data']
      end

      test 'only contain internal profiles by default' do
        internal = Profile.create!(
          account: accounts(:test), name: 'foo', ref_id: 'foo',
          benchmark: benchmarks(:one),
          parent_profile: profiles(:one)
        )
        get v1_profiles_url
        assert_response :success

        profiles = JSON.parse(response.body)
        assert_equal internal.id, profiles['data'].first['id']
      end

      test 'all profile types can be requested at the same time' do
        profiles(:two).update! parent_profile_id: profiles(:one).id
        internal = Profile.create!(
          account: accounts(:test), name: 'foo', ref_id: 'foo',
          benchmark: benchmarks(:one),
          parent_profile: profiles(:one)
        )
        external = Profile.create!(
          account: accounts(:test), name: 'bar', ref_id: 'bar',
          external: true,
          benchmark: benchmarks(:one),
          parent_profile: profiles(:one)
        )
        search_query = 'canonical=true or canonical=false '\
                       'or external=false or external=true'
        get v1_profiles_url, params: { search: search_query }
        assert_response :success

        profiles = JSON.parse(response.body)
        returned_ids = profiles['data'].map { |profile| profile['id'] }
        assert_equal 3, profiles['data'].length
        assert_includes returned_ids, internal.id
        assert_includes returned_ids, external.id
        assert_includes returned_ids, profiles(:one).id
      end
    end

    class DestroyTest < ProfilesControllerTest
      require 'sidekiq/testing'
      Sidekiq::Testing.inline!

      test 'destroy an existing, accessible profile' do
        profile_id = profiles(:one).id
        assert_difference('Profile.count' => -1) do
          delete profile_path(profile_id)
        end
        assert_response :success
        assert_equal 202, response.status, 'Response should be 202 accepted'
        assert_equal profile_id, JSON.parse(response.body).dig('data', 'id'),
                     'Profile ID did not match deleted profile'
      end

      test 'v1 destroy an existing, accessible profile' do
        profile_id = profiles(:one).id
        assert_difference('Profile.count' => -1) do
          delete v1_profile_path(profile_id)
        end
        assert_response :success
        assert_equal 202, response.status, 'Response should be 202 accepted'
        assert_equal profile_id, JSON.parse(response.body).dig('data', 'id'),
                     'Profile ID did not match deleted profile'
      end

      test 'destroy a non-existant profile' do
        profile_id = profiles(:one).id
        profiles(:one).destroy
        assert_difference('Profile.count' => 0) do
          delete v1_profile_path(profile_id)
        end
        assert_response :not_found
      end

      test 'destroy an existing, not accessible profile' do
        profiles(:two).update! parent_profile: profiles(:one)
        assert_difference('Profile.count' => 0) do
          delete v1_profile_path(profiles(:two).id)
        end
        assert_response :not_found
      end

      test 'destroy an existing, accessible profile that is not authorized '\
           'to be deleted' do
        assert_difference('Profile.count' => 0) do
          delete v1_profile_path(profiles(:two).id)
        end
        assert_response :forbidden
      end
    end
  end
end
