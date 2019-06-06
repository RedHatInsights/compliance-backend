class CreateJoinTableRuleReferenceRules < ActiveRecord::Migration[5.2]
  def change
    create_join_table :rules, :rule_references, column_options: { type: :uuid } do |t|
      t.index [:rule_id, :rule_reference_id], name: 'idx_rule_id_and_rule_reference_id'
      t.index [:rule_reference_id, :rule_id], name: 'idx_rule_rule_reference_id_and_rule_id'
    end
  end
end
