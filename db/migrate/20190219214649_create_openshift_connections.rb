class CreateOpenshiftConnections < ActiveRecord::Migration[5.2]
  def change
    create_table :openshift_connections, id: :uuid do |t|
      t.string :api_url
      t.string :registry_api_url
      t.string :username
      t.string :encrypted_token
      t.string :encrypted_token_iv
      t.references :account, type: :uuid, index: true
      t.timestamps
    end
    add_index(:openshift_connections, :encrypted_token_iv, unique: true)
  end
end
