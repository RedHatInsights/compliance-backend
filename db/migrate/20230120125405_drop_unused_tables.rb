class DropUnusedTables < ActiveRecord::Migration[7.0]
  def change
    drop_table :rule_group_rules do |t|
      t.uuid "rule_group_id"
      t.uuid "rule_id"
      t.index ["rule_group_id", "rule_id"], name: "index_rule_group_rules_on_rule_group_id_and_rule_id", unique: true
      t.index ["rule_group_id"], name: "index_rule_group_rules_on_rule_group_id"
      t.index ["rule_id"], name: "index_rule_group_rules_on_rule_id"
    end

    drop_table :rule_references_rules do |t|
      t.uuid "rule_id", null: false
      t.uuid "rule_reference_id", null: false
      t.index ["rule_id", "rule_reference_id"], name: "index_rule_references_rules_on_rule_id_and_rule_reference_id", unique: true
      t.index ["rule_id"], name: "index_rule_references_rules_on_rule_id"
      t.index ["rule_reference_id"], name: "index_rule_references_rules_on_rule_reference_id"
    end

    drop_table :rule_references do |t|
      t.string "href"
      t.string "label"
      t.index ["href", "label"], name: "index_rule_references_on_href_and_label", unique: true
    end

    drop_table :rule_identifiers do |t|
      t.string "label"
      t.string "system"
      t.uuid "rule_id"
      t.index ["label", "system", "rule_id"], name: "index_rule_identifiers_on_label_and_system_and_rule_id", unique: true
      t.index ["rule_id"], name: "index_rule_identifiers_on_rule_id"
    end

    drop_table :profile_rule_groups do |t|
      t.uuid "profile_id", null: false
      t.uuid "rule_group_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["profile_id", "rule_group_id"], name: "index_profile_rule_groups_on_profile_id_and_rule_group_id", unique: true
      t.index ["profile_id"], name: "index_profile_rule_groups_on_profile_id"
      t.index ["rule_group_id"], name: "index_profile_rule_groups_on_rule_group_id"
    end
  end
end
