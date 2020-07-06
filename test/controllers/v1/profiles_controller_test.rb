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

    class CreateTest < ProfilesControllerTest
      fixtures :accounts, :benchmarks, :profiles

      NAME = 'A new name'
      DESCRIPTION = 'A new description'
      COMPLIANCE_THRESHOLD = 93.5
      BUSINESS_OBJECTIVE = 'LATAM Expansion'

      test 'create without data' do
        assert_difference('Profile.count' => 0) do
          post profiles_path, params: { data: {} }
        end
        assert_response :unprocessable_entity
        assert_match 'param is missing or the value is empty: data',
                     JSON.parse(response.body).dig('errors')
      end

      test 'create with invalid data' do
        assert_difference('Profile.count' => 0) do
          post profiles_path, params: { data: 'foo' }
        end
        assert_response :unprocessable_entity
        assert_match 'data must be a hash',
                     JSON.parse(response.body).dig('errors')
      end

      test 'create with empty attributes' do
        assert_difference('Profile.count' => 0) do
          post profiles_path, params: { data: { attributes: {} } }
        end
        assert_response :unprocessable_entity
        assert_match 'param is missing or the value is empty: data',
                     JSON.parse(response.body).dig('errors')
      end

      test 'create with invalid attributes' do
        assert_difference('Profile.count' => 0) do
          post profiles_path, params: { data: { attributes: 'invalid' } }
        end
        assert_response :unprocessable_entity
        assert_match 'attributes must be a hash',
                     JSON.parse(response.body).dig('errors')
      end

      test 'create with empty parent_profile_id' do
        assert_difference('Profile.count' => 0) do
          post profiles_path, params: params(
            attributes: { parent_profile_id: '' }
          )
        end
        assert_response :unprocessable_entity
        assert_match 'param is missing or the value is empty: '\
                     'parent_profile_id',
                     JSON.parse(response.body).dig('errors')
      end

      test 'create with an unfound parent_profile_id' do
        post profiles_path, params: params(
          attributes: { parent_profile_id: 'notfound' }
        )
        assert_response :not_found
      end

      test 'create with a found parent_profile_id but existing ref_id '\
           'in the account' do
        assert_difference('Profile.count' => 0) do
          post profiles_path, params: params(
            attributes: { parent_profile_id: profiles(:one).id }
          )
        end
        assert_response :not_acceptable
      end

      test 'create with a found parent_profile_id and nonexisting ref_id '\
           'in the account' do
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: { parent_profile_id: profiles(:two).id }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
      end

      test 'create with a business objective' do
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: {
              parent_profile_id: profiles(:two).id,
              business_objective: BUSINESS_OBJECTIVE
            }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
        assert_equal BUSINESS_OBJECTIVE,
                     parsed_data.dig('attributes', 'business_objective')
      end

      test 'create with some customized profile attributes' do
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: {
              parent_profile_id: profiles(:two).id,
              name: NAME, description: DESCRIPTION
            }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
        assert_equal NAME, parsed_data.dig('attributes', 'name')
        assert_equal DESCRIPTION, parsed_data.dig('attributes', 'description')
      end

      test 'create with all customized profile attributes' do
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: {
              parent_profile_id: profiles(:two).id,
              name: NAME, description: DESCRIPTION,
              compliance_threshold: COMPLIANCE_THRESHOLD,
              business_objective: BUSINESS_OBJECTIVE
            }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
        assert_equal NAME, parsed_data.dig('attributes', 'name')
        assert_equal DESCRIPTION, parsed_data.dig('attributes', 'description')
        assert_equal COMPLIANCE_THRESHOLD,
                     parsed_data.dig('attributes', 'compliance_threshold')
        assert_equal BUSINESS_OBJECTIVE,
                     parsed_data.dig('attributes', 'business_objective')
      end

      test 'create copies rules from the parent profile' do
        profiles(:two).update!(rules: [profiles(:two).benchmark.rules.first])
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: {
              parent_profile_id: profiles(:two).id
            }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
        assert_equal(
          Set.new(profiles(:two).rule_ids),
          Set.new(parsed_data.dig('relationships', 'rules', 'data')
                             .map { |r| r['id'] })
        )
      end

      test 'create allows custom rules' do
        rule_ids = profiles(:two).benchmark.rules.pluck(:id)
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: {
              parent_profile_id: profiles(:two).id
            },
            relationships: {
              rules: {
                data: rule_ids.map do |id|
                  { id: id, type: 'rule' }
                end
              }
            }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
        assert_equal(
          Set.new(rule_ids),
          Set.new(parsed_data.dig('relationships', 'rules', 'data')
                             .map { |r| r['id'] })
        )
      end

      test 'create only adds custom rules from the parent profile benchmark' do
        bm = profiles(:two).benchmark
        bm2 = Xccdf::Benchmark.create!(ref_id: 'foo', title: 'foo', version: 1,
                                       description: 'foo')
        bm2.update!(rules: [bm.rules.last])
        assert(bm.rules.one?)
        profiles(:two).update!(rules: [bm.rules.first])
        rule_ids = bm.rules.pluck(:id) + bm2.rules.pluck(:id)
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: {
              parent_profile_id: profiles(:two).id
            },
            relationships: {
              rules: {
                data: rule_ids.map do |id|
                  { id: id, type: 'rule' }
                end
              }
            }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
        assert_equal(
          Set.new(bm.rule_ids),
          Set.new(parsed_data.dig('relationships', 'rules', 'data')
                             .map { |r| r['id'] })
        )
      end

      test 'create only adds custom rules from the parent profile benchmark'\
           'and defaults to parent profile rules' do
        bm = profiles(:two).benchmark
        bm2 = Xccdf::Benchmark.create!(ref_id: 'foo', title: 'foo', version: 1,
                                       description: 'foo')
        bm2.update!(rules: [bm.rules.last])
        assert(bm.rules.one?)
        profiles(:two).update!(rules: [bm.rules.first])
        rule_ids = bm2.rules.pluck(:id)
        assert_difference('Profile.count' => 1) do
          post profiles_path, params: params(
            attributes: {
              parent_profile_id: profiles(:two).id
            },
            relationships: {
              rules: {
                data: rule_ids.map do |id|
                  { id: id, type: 'rule' }
                end
              }
            }
          )
        end
        assert_response :created
        assert_equal accounts(:test).id,
                     parsed_data.dig('relationships', 'account', 'data', 'id')
        assert_equal(
          Set.new(profiles(:two).rule_ids),
          Set.new(parsed_data.dig('relationships', 'rules', 'data')
                             .map { |r| r['id'] })
        )
      end
    end
  end
end
