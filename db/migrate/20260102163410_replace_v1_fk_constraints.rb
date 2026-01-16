class ReplaceV1FkConstraints < ActiveRecord::Migration[8.0]
  FK_LIST = [
    {
      old: { source: "policies", target: "profiles", column: "profile_id" },
      new: { source: "policies", target: "canonical_profiles_v2", column: "profile_id" }
    },
    {
      old: { source: "profiles", target: "profiles", column: "parent_profile_id" },
      new: { source: "profiles", target: "canonical_profiles_v2", column: "parent_profile_id" }
    },
    {
      old: { source: "rule_groups", target: "benchmarks", column: "benchmark_id" },
      new: { source: "rule_groups_v2", target: "security_guides_v2", column: "security_guide_id" }
    },
    {
      old: { source: "rule_groups", target: "rules", column: "rule_id" },
      new: { source: "rule_groups_v2", target: "rules_v2", column: "rule_id" }
    },
    {
      old: { source: "rules", target: "rule_groups", column: "rule_group_id" },
      new: { source: "rules_v2", target: "rule_groups_v2", column: "rule_group_id" }
    },
    {
      old: { source: "value_definitions", target: "benchmarks", column: "benchmark_id" },
      new: { source: "value_definitions_v2", target: "security_guides_v2", column: "security_guide_id" }
    }
  ]

  def up
    FK_LIST.each do |fk|
      recreate_foreign_key(
        fk[:old][:source], fk[:old][:target],
        fk[:new][:source], fk[:new][:target],
        fk[:new][:column], fk[:new][:primary_key]
      )
    end

    remove_foreign_key :rule_references_containers, :rules
  end

  def down
    FK_LIST.each do |fk|
      recreate_foreign_key(
        fk[:new][:source], fk[:new][:target],
        fk[:old][:source], fk[:old][:target],
        fk[:old][:column], fk[:old][:primary_key]
      )
    end

    add_foreign_key :rule_references_containers, :rules
  end

  def recreate_foreign_key(old_source, old_target, new_source, new_target, column, primary_key)
    remove_foreign_key old_source, old_target if foreign_key_exists?(old_source, old_target)

    add_foreign_key new_source, new_target, column: column, primary_key: primary_key
  end
end
