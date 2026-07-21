# frozen_string_literal: true

class AddOwnerIdExpressionIndexToSystems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :systems, "((system_profile ->> 'owner_id'))",
              where: 'deleted_at IS NULL',
              name: 'index_systems_on_owner_id_partial',
              algorithm: :concurrently
  end
end
