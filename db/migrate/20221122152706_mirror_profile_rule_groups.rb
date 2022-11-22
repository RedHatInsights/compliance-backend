class MirrorProfileRuleGroups < ActiveRecord::Migration[7.0]
  def up
    RuleGroupTailoringCopier.run!
  end

  def down
    # nop
    # ProfileRuleGroup.joins(:profile).where.not(profile: { parent_profile_id: nil }).destroy_all
  end
end
