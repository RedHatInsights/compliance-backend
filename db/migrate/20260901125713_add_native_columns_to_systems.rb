class AddNativeColumnsToSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :systems, :owner_id, :uuid
    add_column :systems, :os_major_version, :integer
    add_column :systems, :os_minor_version, :integer
  end
end
