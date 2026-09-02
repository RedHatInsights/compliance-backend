class AddConcurrentIndicesToSystems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :systems, :owner_id,
              where: 'deleted_at IS NULL',
              algorithm: :concurrently,
              if_not_exists: true

    add_index :systems, [:org_id, :os_major_version, :os_minor_version],
              where: 'deleted_at IS NULL',
              algorithm: :concurrently,
              name: 'index_systems_on_org_id_and_os_versions',
              if_not_exists: true
  end
end
