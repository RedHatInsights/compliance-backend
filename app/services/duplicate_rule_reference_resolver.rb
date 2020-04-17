# frozen_string_literal: true

# A service class to merge duplicate RuleReference objects
class DuplicateRuleReferenceResolver
  class << self
    def run!
      @rule_references = nil
      duplicate_rule_references.find_each do |rule_reference|
        if existing_rule_reference(rule_reference)
          migrate_rule_reference(existing_rule_reference(rule_reference),
                                 rule_reference)
        else
          self.existing_rule_reference = rule_reference
        end
      end
    end

    private

    def existing_rule_reference(rule_reference)
      rule_references[[rule_reference.href, rule_reference.label]]
    end

    def existing_rule_reference=(rule_reference)
      rule_references[[rule_reference.href,
                       rule_reference.label]] = rule_reference
    end

    def rule_references
      @rule_references ||= {}
    end

    def duplicate_rule_references
      RuleReference.joins(
        "JOIN (#{grouped_nonunique_rule_reference_tuples.to_sql}) as rr on "\
        'rule_references.href = rr.href AND '\
        'rule_references.label = rr.label'
      )
    end

    def grouped_nonunique_rule_reference_tuples
      RuleReference.select(:href, :label).group(:href, :label)
                   .having('COUNT(id) > 1')
    end

    def migrate_rule_reference(existing_rr, duplicate_rr)
      migrate_rule_reference_rules(existing_rr, duplicate_rr)
      duplicate_rr.destroy
    end

    # rubocop:disable Rails/SkipsModelValidations
    def migrate_rule_reference_rules(existing_rr, duplicate_rr)
      RuleReferencesRule.where(rule_reference: duplicate_rr.id)
                        .where.not(rule: existing_rr.rules)
                        .update_all(rule_reference_id: existing_rr.id)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
