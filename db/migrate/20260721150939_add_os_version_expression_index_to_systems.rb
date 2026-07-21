# frozen_string_literal: true

class AddOsVersionExpressionIndexToSystems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :systems,
              "org_id, (CAST(system_profile -> 'operating_system' ->> 'major' AS int)), (CAST(system_profile -> 'operating_system' ->> 'minor' AS int))",
              where: 'deleted_at IS NULL',
              name: 'index_systems_on_org_id_and_os_version_partial',
              algorithm: :concurrently
  end
end
