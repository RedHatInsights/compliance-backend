class CreateRuleResultsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :rule_results_v2, id: :uuid do |t|
      t.string :result
      t.references :rule, type: :uuid, index: false, null: true
      t.references :test_result, type: :uuid, index: false, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO rule_results_v2 (id, result, rule_id, test_result_id, created_at, updated_at)
      SELECT id, result, rule_id, test_result_id, created_at, updated_at
      FROM rule_results;
    SQL

    change_column_null :rule_results_v2, :rule_id, false
    change_column_null :rule_results_v2, :test_result_id, false
    change_column_null :rule_results_v2, :created_at, false
    change_column_null :rule_results_v2, :updated_at, false

    add_index :rule_results_v2, [:rule_id], name: 'index_rule_results_v2_on_rule_id'
    add_index :rule_results_v2, [:test_result_id], name: 'index_rule_results_v2_on_test_result_id'
    add_index :rule_results_v2, [:test_result_id, :rule_id], unique: true, name: 'index_rule_results_v2_on_test_result_id_and_rule_id'
  end

  def down
    drop_table :rule_results_v2
  end
end
