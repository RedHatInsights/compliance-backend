class AddOsMinorVersionToProfiles < ActiveRecord::Migration[5.2]
  def up
    remove_index :profiles, name: 'uniqueness'
    add_column :profiles, :os_minor_version, :string, null: false, default: ''
    add_index :profiles, :os_minor_version
    add_index :profiles,
              %i[ref_id account_id benchmark_id os_minor_version policy_id],
              unique: true, name: 'uniqueness'
  end

  def down
    remove_index :profiles, name: 'uniqueness'
    remove_index :profiles, :os_minor_version
    remove_column :profiles, :os_minor_version
    add_index :profiles,
              %i[ref_id account_id benchmark_id external policy_id],
              unique: true, name: 'uniqueness'
  end
end
