# frozen_string_literal: true

require 'test_helper'

module V1
  class ProfilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      ::ProfilesController.any_instance.stubs(:authenticate_user)
      User.current = users(:test)
      users(:test).update! account: accounts(:test)
      profiles(:one).update! account: accounts(:test)
    end

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

    test 'tailoring_file with a noncanonical profile returns tailoring file' do
      profiles(:two).update!(rules: [rules(:one), rules(:two)])
      profiles(:one).update!(parent_profile: profiles(:two),
                             rules: [rules(:one)])
      get tailoring_file_v1_profile_url(profiles(:one).id)
      assert_response :success
      assert_equal Mime[:xml].to_s, @response.content_type
    end
  end
end
