# frozen_string_literal: true

require 'test_helper'

class CreateProfileMutationTest < ActiveSupport::TestCase
  setup do
    @query = <<-GRAPHQL
       mutation createProfile($input: createProfileInput!) {
          createProfile(input: $input) {
             profile {
                 id
             }
          }
       }
    GRAPHQL

    @original_profile = profiles(:one)
    users(:test).update account: accounts(:test)
  end

  test 'provide all required arguments' do
    result = Schema.execute(
      @query,
      variables: { input: {
        benchmarkId: @original_profile.benchmark_id,
        cloneFromProfileId: @original_profile.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0
      } },
      context: { current_user: users(:test) }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert cloned_profile.ref_id, 'xccdf-customized'
    assert_equal cloned_profile.rules, @original_profile.rules
    assert_equal cloned_profile.parent_profile, @original_profile
  end

  test 'provide all required arguments with selectedRuleRefIds' do
    result = Schema.execute(
      @query,
      variables: { input: {
        benchmarkId: @original_profile.benchmark_id,
        cloneFromProfileId: @original_profile.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0,
        selectedRuleRefIds: @original_profile.rules.map(&:ref_id)
      } },
      context: { current_user: users(:test) }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert cloned_profile.ref_id, 'xccdf-customized'
    assert_equal cloned_profile.rules, @original_profile.rules
    assert_equal cloned_profile.parent_profile, @original_profile
  end

  test 'tailoring the list of rules via selectedRules' do
    tailored_rules = [rules(:one).ref_id, rules(:two).ref_id]

    result = Schema.execute(
      @query,
      variables: { input: {
        benchmarkId: @original_profile.benchmark_id,
        cloneFromProfileId: @original_profile.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0,
        selectedRuleRefIds: tailored_rules
      } },
      context: { current_user: users(:test) }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert cloned_profile.ref_id, 'xccdf-customized'
    assert_not_equal cloned_profile.rules, @original_profile.rules
    assert_equal Set.new(cloned_profile.rules),
                 Set.new(Rule.where(ref_id: tailored_rules))
    assert_equal cloned_profile.parent_profile, @original_profile
    assert_audited 'Created policy'
    assert_audited 'Updated tailoring of profile'
    assert_audited "#{tailored_rules.count} rules added"
    assert_audited '0 rules removed'
  end
end
