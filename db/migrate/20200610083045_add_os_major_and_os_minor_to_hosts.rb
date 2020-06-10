class AddOsMajorAndOsMinorToHosts < ActiveRecord::Migration[5.2]
  def change
    add_column :hosts, :os_major, :integer
    add_column :hosts, :os_minor, :integer
  end
end
