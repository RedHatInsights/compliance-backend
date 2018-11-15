class CreateTableProfileHosts < ActiveRecord::Migration[5.2]
  def change
    create_table :profile_hosts, id: :uuid do |t|
      t.references :profile, type: :uuid, index: true, null: false
      t.references :host, type: :uuid, index: true, null: false

      t.timestamps null: true
    end
    add_index(:profile_hosts, %i[profile_id host_id], unique: true)
  end
end
