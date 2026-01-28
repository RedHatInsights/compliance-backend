class DropDeadProfiles < ActiveRecord::Migration[7.0]
  def up
    # Removed so we're able to change the table name of Profiles
    # orphaned_policies = Policy.left_outer_joins(:profiles).where(profiles: { id: nil } )
    # PolicyHost.where(policy: orphaned_policies).delete_all
    # orphaned_policies.delete_all
  end
end
