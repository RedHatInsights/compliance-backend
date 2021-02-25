# frozen_string_literal: true

# Methods that are related to a profile's rules
module ProfileRules
  extend ActiveSupport::Concern

  included do
    has_many :profile_rules, dependent: :delete_all
    has_many :rules, through: :profile_rules, source: :rule

    def update_rules(ids: nil, ref_ids: nil)
      removed = ProfileRule.where(
        rule_id: rule_ids_to_destroy(ids, ref_ids), profile_id: id
      ).destroy_all

      ids_to_add = rule_ids_to_add(ids, ref_ids)
      imported = ProfileRule.import!(ids_to_add.map do |rule_id|
        ProfileRule.new(profile_id: id, rule_id: rule_id)
      end)

      [imported.ids.count, removed.count]
    end

    private

    def rule_ids_to_add(ids, ref_ids)
      new_rules(ids, ref_ids).where.not(id: rule_ids).pluck(:id)
    end

    def rule_ids_to_destroy(ids, ref_ids)
      rule_ids - new_rules(ids, ref_ids).pluck(:id)
    end

    def new_rules(ids, ref_ids)
      bm_rules = benchmark.rules.select(:id)

      rel = if ids
              bm_rules.where(id: ids)
            elsif ref_ids
              bm_rules.where(ref_id: ref_ids)
            end

      rel&.any? ? rel : bm_rules.where(id: parent_profile_rule_ids)
    end

    def parent_profile_rule_ids
      parent_profile&.rules&.select(:id) || []
    end
  end
end
