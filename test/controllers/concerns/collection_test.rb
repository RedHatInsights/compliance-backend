# frozen_string_literal: true

require 'test_helper'

class ControlleCollectionTest < ActionDispatch::IntegrationTest
  setup do
    ApplicationController.any_instance
                         .expects(:authenticate_user)
                         .at_least_once
                         .yields
    User.current = FactoryBot.create(:user)
  end

  test 'deterministic pagination' do
    created_profiles = FactoryBot.create_list(
      :profile, 44,
      name: 'The same name',
      parent_profile_id: nil
    )

    collected_profiles = []
    url_path = v1_profiles_url
    params = { search: '', sort_by: 'name' }
    100.times do
      get url_path, params: params
      assert_response :success
      data = response.parsed_body

      batch = data['data']
      batch_ids = batch.map { |p| p['id'] }.to_set
      collected_ids = collected_profiles.map { |p| p['id'] }.to_set
      intersection = collected_ids.intersection(batch_ids)

      assert_equal 0, intersection.count,
                   'Intersected items from previous page(s):' \
                   " #{intersection}"

      collected_profiles.append(*batch)

      url_path = data.dig('links', 'next')
      break unless url_path

      params = { sort_by: 'name' }
    end

    assert_equal created_profiles.count, collected_profiles.count
    created_ids = created_profiles.map(&:id).to_set
    assert_equal created_profiles.count, created_ids.count
    collected_ids = collected_profiles.map { |p| p['id'] }.to_set
    assert_equal 0, (created_ids - collected_ids).count
  end
end
