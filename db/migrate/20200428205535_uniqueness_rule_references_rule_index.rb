class UniquenessRuleReferencesRuleIndex < ActiveRecord::Migration[5.2]
  class RuleReferencesRule < ApplicationRecord; end
  class NewRuleReferencesRule < ApplicationRecord; end

  def up
    ids_to_keep = RuleReferencesRule.group(
      'rule_id, rule_reference_id'
    ).having('count(id) > 1').select(Arel.sql('MIN(id)'))
    create_table :new_rule_references_rules, id: false do |t|
      t.references :rule, type: :uuid, index: true, null: false
      t.references :rule_reference, type: :uuid, index: true, null: false
    end
    columns = [:rule_id, :rule_reference_id]
    to_keep = RuleReferencesRule.where(id: ids_to_keep)
    to_keep.each_with_index do |batch, index|
      NewRuleReferencesRule.import!(
        columns,
        batch.pluck(:rule_id, :rule_reference_id)
      )
    end
    drop_table :rule_references_rules
    rename_table :new_rule_references_rules, :rule_references_rules
    add_index :rule_references_rules, %i[rule_id rule_reference_id],
      unique: true
  end
end
