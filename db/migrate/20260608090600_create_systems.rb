class CreateSystems < ActiveRecord::Migration[7.1]
  def change
    create_table :systems, id: :uuid do |t|
      t.string :account, limit: 10
      t.string :org_id, limit: 10, null: false
      t.string :display_name, limit: 200, null: false
      t.jsonb :tags, null: false, default: {}
      t.datetime :updated, null: false
      t.datetime :created, null: false
      t.datetime :stale_timestamp, null: false
      t.jsonb :system_profile, null: false, default: {}
      t.jsonb :groups, default: []
      t.uuid :insights_id
      t.datetime :deleted_at
    end

    add_index :systems, :insights_id, unique: true
  end
end
