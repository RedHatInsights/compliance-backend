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
        assert_difference('Profile.count' => 0) do
          delete v1_profile_path(profiles(:two).id)
        end
        assert_response :not_found
      end
    end
  end
end
