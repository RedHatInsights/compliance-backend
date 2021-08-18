# frozen_string_literal: true

# This class cleans up unused rules and reimports
class UpstreamCleanupService
  class << self
    def run!
      # Clean up rules that don't belong to any profile
      Rule.where.not(id: ProfileRule.select(:rule_id)).delete_all

      # Clean up rules that belong only to canonical profiles
      delete_rules(select_rules)

      # Clean up canonical profiles that don't have any child profiles
      delete_profiles

      # Reimport all rules if we're not in the testing environment
      Rake::Task['ssg:import_rhel_supported'].execute unless Rails.env.test?
    end

    private

    def delete_profiles
      Profile.canonical.where.not(id: used_canonicals).delete_all
    end

    def select_rules
      used_rules = ProfileRule.where(profile_id: used_canonicals)
                              .select(:rule_id)

      Rule.where.not(id: RuleResult.select(:rule_id))
          .where.not(id: used_rules).select(:id)
    end

    def delete_rules(rules)
      RuleReferencesRule.where(rule_id: rules).delete_all
      RuleReference.left_outer_joins(:rules).where('rules.id' => nil).delete_all
      RuleIdentifier.where(rule_id: rules).delete_all
      rules.delete_all
    end

    def used_canonicals
      @used_canonicals ||= Profile.canonical(false)
                                  .select(:parent_profile_id).distinct
    end
  end
end
