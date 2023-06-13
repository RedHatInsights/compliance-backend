# frozen_string_literal: true

# A service class to merge duplicate Rule objects
class DuplicateRuleResolver
  class << self
    def run!
      @rules = nil
      duplicate_rules.find_each do |rule|
        if existing_rule(rule)
          migrate_rule(existing_rule(rule), rule)
        else
          self.existing_rule = rule
        end
      end
    end

    private

    def existing_rule(rule)
      rules[[rule.ref_id, rule.benchmark_id]]
    end

    def existing_rule=(rule)
      rules[[rule.ref_id, rule.benchmark_id]] = rule
    end

    def rules
      @rules ||= {}
    end

    def migrate_rule(existing_r, duplicate_r)
      migrate_profile_rules(existing_r, duplicate_r)
      migrate_rule_results(existing_r, duplicate_r)
      duplicate_r.destroy # RuleResults
    end

    def duplicate_rules
      Rule.joins(
        "JOIN (#{grouped_nonunique_rule_tuples.to_sql}) as r on " \
        'rules.ref_id = r.ref_id AND ' \
        'rules.benchmark_id = r.benchmark_id'
      )
    end

    def grouped_nonunique_rule_tuples
      Rule.select(:ref_id, :benchmark_id)
          .group(:ref_id, :benchmark_id)
          .having('COUNT(id) > 1')
    end

    # rubocop:disable Rails/SkipsModelValidations
    def migrate_profile_rules(existing_r, duplicate_r)
      duplicate_r.profile_rules.where.not(profile: existing_r.profiles)
                 .update_all(rule_id: existing_r.id)
    end

    def migrate_rule_results(existing_r, duplicate_r)
      duplicate_r.rule_results.update_all(rule_id: existing_r.id)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
