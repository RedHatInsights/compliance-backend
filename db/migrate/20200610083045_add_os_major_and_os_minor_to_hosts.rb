class AddOsMajorAndOsMinorToHosts < ActiveRecord::Migration[5.2]
  def change
    add_column :hosts, :os_major, :integer
    add_column :hosts, :os_minor, :integer
    add_index :hosts, :os_major
    add_index :hosts, :os_minor
  end
end
