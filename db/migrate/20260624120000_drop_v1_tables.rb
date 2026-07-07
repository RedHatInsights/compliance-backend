# frozen_string_literal: true

class DropV1Tables < ActiveRecord::Migration[8.1]
  def up
    drop_table(:rule_results) {}
    drop_table(:profile_rules) {}
    drop_table(:policy_hosts) {}
    drop_table(:test_results) {}
    drop_table(:profiles) {}
    drop_table(:business_objectives) {}
    drop_table(:policies) {}
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
