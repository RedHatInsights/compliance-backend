# frozen_string_literal: true

# This class cleans up unused rules and reimports
class RulesCleanupService
  class << self
    def run!
      # Clean up rules that don't belong to any profile
      Rule.where.not(id: ProfileRule.select(:rule_id)).delete_all

      # Clean up rules that belong only to canonical profiles
      delete_rules(select_rules)

      # Reimport all rules if we're not in the testing environment
      Rake::Task['ssg:import_rhel_supported'].execute unless Rails.env.test?
    end

    def select_rules
      profiles = Profile.canonical(false).select(:parent_profile_id).distinct
      used_rules = ProfileRule.select(:rule_id).where(profile_id: profiles)

      Rule.where.not(id: RuleResult.select(:rule_id))
          .where.not(id: used_rules).select(:id)
    end

    def delete_rules(rules)
      RuleReferencesRule.where(rule_id: rules).delete_all
      RuleReference.left_outer_joins(:rules).where('rules.id' => nil).delete_all
      RuleIdentifier.where(rule_id: rules).delete_all
      rules.delete_all
    end
  end
end
