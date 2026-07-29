# frozen_string_literal: true

class AddOrgIdAndDisplayNameIndexToSystems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :systems, [:org_id, :display_name],
              where: 'deleted_at IS NULL',
              name: 'index_systems_on_org_id_and_display_name_partial',
              algorithm: :concurrently
  end
end
