# frozen_string_literal: true

require 'test_helper'

module V1
  class RulesControllerTest < ActionDispatch::IntegrationTest
    setup do
      User.current = FactoryBot.create(:user)
      @profile = FactoryBot.create(:profile, :with_rules)
    end

    should 'allow access to rules#show with cert auth' do
      account = User.current.account

      encoded_header = Base64.encode64(
        {
          'identity': {
            'org_id': account.org_id,
            'auth_type': IdentityHeader::CERT_AUTH
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      HostInventoryApi.any_instance
                      .expects(:hosts)
                      .returns('results' => [:foo])
      get rule_url(Rule.first),
          headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
    end

    should 'disallow access to rules#index with cert auth' do
      account = User.current.account

      encoded_header = Base64.encode64(
        {
          'identity': {
            'org_id': account.org_id,
            'auth_type': IdentityHeader::CERT_AUTH
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      HostInventoryApi.any_instance
                      .expects(:hosts)
                      .never
      get rules_url,
          headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :forbidden
    end

    context 'authenticated' do
      setup do
        RulesController.any_instance.stubs(:authenticate_user).yields
      end

      should 'index lists all rules' do
        RulesController.any_instance.expects(:policy_scope).with(Rule)
                       .returns(Rule.all).at_least_once
        get v1_rules_url

        assert_response :success
      end

      should 'finds a rule within the user scope' do
        get v1_rule_url(@profile.rules.first.ref_id)
        assert_response :success
      end

      should 'rules can be sorted' do
        medium, high, u1, low, u2 = @profile.rules
        high.update!(severity: 'high')
        medium.update!(severity: 'medium')
        low.update!(severity: 'low')
        u1.update!(title: '1', severity: 'unknown')
        u2.update!(title: 'b', severity: 'unknown')

        get v1_rules_url, params: {
          sort_by: %w[severity title:desc],
          policy_id: @profile.policy.id
        }
        assert_response :success

        result = response.parsed_body
        rules = [u2, u1, low, medium, high].map(&:id)

        assert_equal(rules, result['data'].map do |rule|
          rule['id']
        end)
      end

      should 'return remediation_issue_id as nil if remediation unavailable' do
        rule = @profile.rules.first
        rule.update!(remediation_available: false)

        get v1_rule_url(rule.ref_id)
        assert_response :success
        assert_nil response.parsed_body['data']['attributes']['remediation_issue_id']
      end

      should 'return with remediation_issue_id if remediation available' do
        rule = @profile.rules.first
        rule.update!(remediation_available: true)

        get v1_rule_url(rule.ref_id)
        assert_response :success
        assert response.parsed_body['data']['attributes']['remediation_issue_id']
      end

      should 'fail if wrong sort order is set' do
        get v1_rules_url, params: { sort_by: ['title:foo'] }
        assert_response :unprocessable_entity
      end

      should 'fail if sorting by wrong column' do
        get v1_rules_url, params: { sort_by: ['foo'] }
        assert_response :unprocessable_entity
      end

      should 'fail if invalid include parameter when finding rules' do
        get v1_rules_url, params: { include: ['foo'] }
        assert_response :unprocessable_entity
      end

      should 'fail if invalid include parameter when finding rule by ID' do
        get v1_rule_url(@profile.rules.first.id), params: { include: 'foo' }
        assert_response :unprocessable_entity
      end

      should 'find rules with rule identifier included' do
        get v1_rules_url, params: { include: 'rule_identifier' }
        assert_response :success
      end

      %i[identifier rule_identifier].each do |identifier|
        should "find rules by #{identifier}" do
          rule = FactoryBot.create(:rule, profiles: [@profile], identifier: { label: 'foo-to-find', system: 'bar' })
          get v1_rules_url, params: { search: "#{identifier}=foo-to-find" }
          assert_response :success
          assert_equal response.parsed_body['data'][0]['id'], rule.id
        end
      end

      should 'find rules by identifier implicitly' do
        rule = FactoryBot.create(:rule, profiles: [@profile], identifier: { label: 'foo-to-find', system: 'bar' })
        get v1_rules_url, params: { search: 'foo-to-find' }
        assert_response :success
        assert_equal response.parsed_body['data'][0]['id'], rule.id
      end

      should 'find a rule by ID with rule identifier included' do
        get v1_rule_url(@profile.rules.first.id),
            params: { include: 'rule_identifier' }
        assert_response :success
      end

      should 'finds a rule with similar slug within the user scope' do
        @profile.rules.first.update(
          slug: "#{@profile.rules.first.ref_id}-#{SecureRandom.uuid}"
        )

        get v1_rule_url(@profile.rules.first.ref_id)
        assert_response :success
      end

      should 'finds a rule by ID' do
        get v1_rule_url(@profile.rules.first.id)

        assert_response :success
      end

      should 'finds latest canonical rules' do
        parent = FactoryBot.create(:canonical_profile, :with_rules,
                                   rule_count: 1)

        assert_includes(Rule.latest, parent.rules.last)
        assert_not_includes(User.current.account.profiles.map(&:rules).uniq,
                            parent.rules.last)
        get v1_rule_url(parent.rules.last.ref_id)

        assert_response :success
      end
    end
  end
end
