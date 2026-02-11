class UpdateV1ProfileRulesToVersion2 < ActiveRecord::Migration[8.0]
  def change
    drop_trigger :v1_profile_rules_delete, on: :v1_profile_rules, revert_to_version: 1
    drop_trigger :v1_profile_rules_insert, on: :v1_profile_rules, revert_to_version: 1
    drop_trigger :v1_profile_rules_update, on: :v1_profile_rules, revert_to_version: 1

    update_view :v1_profile_rules, version: 2, revert_to_version: 1

    create_trigger :v1_profile_rules_delete, on: :v1_profile_rules
    create_trigger :v1_profile_rules_insert, on: :v1_profile_rules
    create_trigger :v1_profile_rules_update, on: :v1_profile_rules
  end
end
