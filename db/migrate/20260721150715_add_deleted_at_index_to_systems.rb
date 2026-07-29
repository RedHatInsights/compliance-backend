# frozen_string_literal: true

class AddDeletedAtIndexToSystems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :systems, :deleted_at,
              where: 'deleted_at IS NOT NULL',
              name: 'index_systems_on_deleted_at_partial',
              algorithm: :concurrently
  end
end
