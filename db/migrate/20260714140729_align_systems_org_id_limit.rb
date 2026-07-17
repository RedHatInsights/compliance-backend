# frozen_string_literal: true

class AlignSystemsOrgIdLimit < ActiveRecord::Migration[7.1]
  def up
    change_column :systems, :org_id, :string, limit: 36, null: false
  end

  def down
    change_column :systems, :org_id, :string, limit: 36, null: false
  end
end
