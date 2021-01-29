class DropHosts < ActiveRecord::Migration[5.2]
  def up
    if foreign_key_exists?("policy_hosts", "hosts")
      remove_foreign_key "policy_hosts", "hosts"
    end
    drop_table :hosts
  end

  def down
    create_table "hosts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.uuid "account_id"
      t.integer "os_major_version"
      t.integer "os_minor_version"
      t.index ["account_id"], name: "index_hosts_on_account_id"
      t.index ["name"], name: "index_hosts_on_name"
      t.index ["os_major_version"], name: "index_hosts_on_os_major_version"
      t.index ["os_minor_version"], name: "index_hosts_on_os_minor_version"
    end
  end
end
