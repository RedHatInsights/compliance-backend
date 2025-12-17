class CreateRulesV2Table < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      SELECT *
      INTO rules_v2
      FROM v2_rules;
    SQL
  end

  def down
    drop_table :rules_v2
  end
end
