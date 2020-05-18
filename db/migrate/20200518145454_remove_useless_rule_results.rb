# This migration is meant to remove all of the rule results which are errors.
# These are a byproduct of previous states of the application, and
# in production they are all very old RuleResults.
class RemoveUselessRuleResults < ActiveRecord::Migration[5.2]
  def up
    RuleResult.where(test_result_id: nil).delete_all

    rule_ids = RuleResult.select(:rule_id).distinct.pluck(:rule_id)
    found_rule_ids = Rule.where(id: rule_ids).pluck(:id)

    unfound_rule_ids = rule_ids - found_rule_ids
    RuleResult.where(rule_id: unfound_rule_ids).delete_all

    host_ids = RuleResult.select(:host_id).distinct.pluck(:host_id)
    found_host_ids = Host.where(id: host_ids).pluck(:id)

    unfound_host_ids = host_ids - found_host_ids
    RuleResult.where(host_id: unfound_host_ids).delete_all
  end
end
