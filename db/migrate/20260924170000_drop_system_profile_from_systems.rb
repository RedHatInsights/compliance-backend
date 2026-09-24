# frozen_string_literal: true

class DropSystemProfileFromSystems < ActiveRecord::Migration[8.1]
  def change
    remove_index :systems, name: 'index_systems_on_owner_id_partial'
    remove_index :systems, name: 'index_systems_on_org_id_and_os_version_partial'
    remove_column :systems, :system_profile, :jsonb, default: {}, null: false
  end
end
