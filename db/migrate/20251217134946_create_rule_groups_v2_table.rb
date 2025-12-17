class CreateRuleGroupsV2Table < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      SELECT *
      INTO rule_groups_v2
      FROM v2_rule_groups;
    SQL
  end

  def down
    drop_table :rule_groups_v2
  end
end
