# frozen_string_literal: true

require 'test_helper'

class UpstreamCleanupServiceTest < ActiveSupport::TestCase
  setup do
    @cp = FactoryBot.create(:canonical_profile, :with_rules)
    acc = FactoryBot.create(:account)
    @profile = FactoryBot.create(:profile, :with_rules, account: acc)

    r1, r2 = @cp.rules.sample(2)
    @unused_rr = FactoryBot.create(:rule_reference, rules: [r1, r2])
    FactoryBot.create(:rule_reference, rules: [@profile.rules.sample, r1])
    FactoryBot.create(:rule_identifier, rule: r1)
    FactoryBot.create(:rule_identifier, rule: @profile.rules.sample)
  end

  test 'delete unused rules' do
    assert_difference(
      'Profile.canonical.count' => -1,
      'Profile.canonical(false).count' => 0,
      'Profile.canonical.flat_map(&:rules).count' => -@cp.rules.count,
      'Profile.canonical(false).flat_map(&:rules).count' => 0,
      'RuleReference.count' => -1,
      'RuleReferencesRule.count' => -3,
      'RuleIdentifier.count' => -1
    ) do
      UpstreamCleanupService.run!
    end

    assert_empty Profile.where(id: @cp.id)
    assert_equal @profile.reload.rules.count, 5
    assert @profile.parent_profile
  end
end
