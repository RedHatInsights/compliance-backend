class CreateProfileImagestreams < ActiveRecord::Migration[5.2]
  def change
    create_table :profile_imagestreams, id: :uuid do |t|
      t.references :profile, type: :uuid, index: true, null: false
      t.references :imagestream, type: :uuid, index: true, null: false

      t.timestamps null: true
    end
    add_index(:profile_imagestreams, %i[profile_id imagestream_id], unique: true)
  end
end
