class CreateImagestreams < ActiveRecord::Migration[5.2]
  def change
    create_table :imagestreams, id: :uuid do |t|
      t.string :name
      t.references :openshift_connection, type: :uuid, index: true
      t.timestamps
    end
    add_index :imagestreams, :name
  end
end
