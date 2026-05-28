class ReplaceRemainingV1FkConstraints < ActiveRecord::Migration[8.0]
  FK_LIST = [
    {
      old: { source: "policies", target: "accounts" },
      new: { source: "policies_v2", target: "accounts", column: "account_id" }
    },
    {
      old: { source: "policies", target: "canonical_profiles_v2", column: "profile_id" },
      new: { source: "policies_v2", target: "canonical_profiles_v2", column: "profile_id" }
    },
    {
      old: { source: "policy_hosts", target: "policies" },
      new: { source: "policy_systems_v2", target: "policies_v2", column: "policy_id" }
    },
    {
      old: { source: "profiles", target: "canonical_profiles_v2", column: "parent_profile_id" },
      new: { source: "tailorings_v2", target: "canonical_profiles_v2", column: "profile_id" }
    },
    {
      old: { source: "profiles", target: "policies" },
      new: { source: "tailorings_v2", target: "policies_v2", column: "policy_id" }
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

    remove_foreign_key :policies, :business_objectives if foreign_key_exists?(:policies, :business_objectives)
  end

  def down
    FK_LIST.each do |fk|
      recreate_foreign_key(
        fk[:new][:source], fk[:new][:target],
        fk[:old][:source], fk[:old][:target],
        fk[:old][:column], fk[:old][:primary_key]
      )
    end

    add_foreign_key :policies, :business_objectives
  end

  def recreate_foreign_key(old_source, old_target, new_source, new_target, column, primary_key)
    remove_foreign_key old_source, old_target if foreign_key_exists?(old_source, old_target)

    add_foreign_key new_source, new_target, column: column, primary_key: primary_key
  end
end
