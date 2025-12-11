class CreateTailoringRulesV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :tailoring_rules_v2, id: :uuid do |t|
      t.uuid :tailoring_id
      t.uuid :rule_id

      t.timestamps
    end

    add_index :tailoring_rules_v2, [:tailoring_id, :rule_id], unique: true, name: 'index_tailoring_rules_v2_on_tailoring_id_and_rule_id'
    add_index :tailoring_rules_v2, [:tailoring_id], name: 'index_tailoring_rules_v2_on_tailoring_id'
    add_index :tailoring_rules_v2, [:rule_id], name: 'index_tailoring_rules_v2_on_rule_id'
  end
end
