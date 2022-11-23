# frozen_string_literal: true

require 'test_helper'

class TailorProfileMutationTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    parent = FactoryBot.create(:canonical_profile, :with_rules, :with_rule_groups, rule_count: 1, rule_group_count: 1)
    @profile = FactoryBot.create(
      :profile,
      account: @user.account,
      parent_profile: parent,
      benchmark: parent.benchmark
    )
    @rule = parent.rules.first
    @rule_group = parent.rule_groups.first
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  QUERY = <<-GRAPHQL
     mutation tailorProfile($input: tailorProfileInput!) {
        tailorProfile(input: $input) {
           profile {
               id
           }
        }
     }
  GRAPHQL

  %i[rule ruleGroup].each do |field|
    next if field == :ruleGroup # FIXME: final cleanup of RHICOMPL-2124

    should "fail if no #{field} is passed" do
      assert_raises ActionController::ParameterMissing do
        Schema.execute(
          QUERY,
          variables: {
            input: {
              id: @profile.id,
              ruleIds: [],
              ruleGroupIds: []
            }.reject { |key, _| key.to_s.starts_with?(field.to_s) }
          },
          context: { current_user: @user }
        )['data']['tailorProfile']['profile']
      end
    end
  end

  # FIXME: final cleanup of RHICOMPL-2124
  should 'add default rule groups to a profile' do
    assert_empty @profile.rule_groups

    Schema.execute(
      QUERY,
      variables: {
        input: {
          id: @profile.id,
          ruleIds: [@rule.id]
        }
      },
      context: { current_user: @user }
    )['data']['tailorProfile']['profile']

    assert_equal Set.new(@profile.reload.rule_groups),
                 Set.new([@rule_group])
  end

  %i[id ref_id].each do |key|
    should "add rules and rule_groups to a profile by #{key}" do
      assert_empty @profile.rules
      assert_empty @profile.rule_groups

      Schema.execute(
        QUERY,
        variables: {
          input: {
            id: @profile.id,
            "rule#{key.to_s.pluralize.camelize}" => [@rule.send(key)],
            "ruleGroup#{key.to_s.pluralize.camelize}" => [@rule_group.send(key)]
          }
        },
        context: { current_user: @user }
      )['data']['tailorProfile']['profile']

      assert_equal Set.new(@profile.reload.rules),
                   Set.new([@rule])

      assert_equal Set.new(@profile.reload.rule_groups),
                   Set.new([@rule_group])
    end

    should "remove rules and rule_groups from a profile by #{key}" do
      ProfileRule.where(profile: @profile.parent_profile).update(profile: @profile)
      ProfileRuleGroup.where(profile: @profile.parent_profile).update(profile: @profile)

      assert_not_empty @profile.reload.rules
      assert_not_empty @profile.rule_groups

      assert_audited_success 'Updated rule and group assignments of profile', @profile.id

      Schema.execute(
        QUERY,
        variables: {
          input: {
            id: @profile.id,
            "rule#{key.to_s.pluralize.camelize}" => [],
            "ruleGroup#{key.to_s.pluralize.camelize}" => []
          }
        },
        context: { current_user: @user }
      )['data']['tailorProfile']['profile']

      assert_empty @profile.reload.rules
      assert_empty @profile.rule_groups
    end
  end
end
