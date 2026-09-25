# frozen_string_literal: true

class DropSystemProfileFromSystems < ActiveRecord::Migration[8.1]
  def up
    remove_index :systems, name: 'index_systems_on_owner_id_partial'
    remove_index :systems, name: 'index_systems_on_org_id_and_os_version_partial'
    remove_column :systems, :system_profile, :jsonb, default: {}, null: false
  end

  def down
    add_column :systems, :system_profile, :jsonb, default: {}, null: false
    add_index :systems, "((system_profile ->> 'owner_id'))",
              where: 'deleted_at IS NULL',
              name: 'index_systems_on_owner_id_partial'
    add_index :systems,
              "org_id, (CAST(system_profile -> 'operating_system' ->> 'major' AS int)), " \
              "(CAST(system_profile -> 'operating_system' ->> 'minor' AS int))",
              where: 'deleted_at IS NULL',
              name: 'index_systems_on_org_id_and_os_version_partial'
  end
end
