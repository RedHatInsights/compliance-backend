class AddOsMajorAndOsMinorToHosts < ActiveRecord::Migration[5.2]
  def change
    add_column :hosts, :os_major_version, :integer
    add_column :hosts, :os_minor_version, :integer
    add_index :hosts, :os_major_version
    add_index :hosts, :os_minor_version
  end
end
