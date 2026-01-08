class DropReplacedV2Views < ActiveRecord::Migration[8.0]
  def change
    drop_view :security_guides, revert_to_version: 2
    drop_view :v2_value_definitions, revert_to_version: 1
    drop_view :canonical_profiles, revert_to_version: 3
    drop_view :v2_rules, revert_to_version: 2
    drop_view :v2_rule_groups, revert_to_version: 1
  end
end
