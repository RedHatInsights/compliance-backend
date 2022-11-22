# frozen_string_literal: true

# A service class to copy rule group tailoring to non-canonical profiles
class RuleGroupTailoringCopier
  class << self
    JOIN = Arel.sql('INNER JOIN profile_rule_groups ON profiles.parent_profile_id = profile_rule_groups.profile_id')

    def run!
      to_import = Profile.canonical(false).joins(JOIN).pluck('profiles.id', 'profile_rule_groups.rule_group_id')
      ProfileRuleGroup.import!(%i[profile_id rule_group_id], to_import)
    end
  end
end
