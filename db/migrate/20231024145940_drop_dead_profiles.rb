class DropDeadProfiles < ActiveRecord::Migration[7.0]
  def up
    orphaned_policies = Policy.left_outer_joins(:profiles).where(profiles: { id: nil } )
    PolicyHost.where(policy: orphaned_policies).delete_all
    orphaned_policies.delete_all
  end
end
