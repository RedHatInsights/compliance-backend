# frozen_string_literal: true

class AddTagsAndGroupsGinIndexesToSystems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :systems, :tags,
              using: :gin,
              opclass: :jsonb_path_ops,
              where: 'deleted_at IS NULL',
              name: 'index_systems_on_tags_gin_partial',
              algorithm: :concurrently

    add_index :systems, :groups,
              using: :gin,
              opclass: :jsonb_path_ops,
              where: 'deleted_at IS NULL',
              name: 'index_systems_on_groups_gin_partial',
              algorithm: :concurrently

    add_index :systems, :groups,
              where: "deleted_at IS NULL AND groups = '[]'::jsonb",
              name: 'index_systems_on_empty_groups_partial',
              algorithm: :concurrently
  end
end
