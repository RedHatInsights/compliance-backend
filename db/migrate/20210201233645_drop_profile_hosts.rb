class DropProfileHosts < ActiveRecord::Migration[5.2]
  def up
    drop_table :profile_hosts
  end

  def down
    create_table :profile_hosts, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "profile_id", null: false
      t.uuid "host_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["host_id"], name: "index_profile_hosts_on_host_id"
      t.index ["profile_id", "host_id"], name: "index_profile_hosts_on_profile_id_and_host_id", unique: true
      t.index ["profile_id"], name: "index_profile_hosts_on_profile_id"
    end
  end
end
