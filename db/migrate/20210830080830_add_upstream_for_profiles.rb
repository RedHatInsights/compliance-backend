class AddUpstreamForProfiles < ActiveRecord::Migration[5.2]
  def up
    add_column :profiles, :upstream, :boolean
    add_index :profiles, :upstream

    # Removed so we're able to change the table name of Profiles

    # Initially all canonical profiles are marked as upstream
    # Profile.canonical.update_all(upstream: true)
  end

  def down
    remove_column :profiles, :upstream
    remove_index :profiles, :upstream
  end
end
