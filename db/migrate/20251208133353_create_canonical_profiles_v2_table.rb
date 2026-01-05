class CreateCanonicalProfilesV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :canonical_profiles_v2, id: :uuid do |t|
      t.string :title
      t.string :ref_id
      t.string :description
      t.uuid :security_guide_id
      t.boolean :upstream
      t.jsonb :value_overrides, default: {}

      t.timestamps
    end

    add_index :canonical_profiles_v2, [:title], name: 'index_canonical_profiles_v2_on_title'
    add_index :canonical_profiles_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_canonical_profiles_v2_on_ref_id_and_security_guide_id'
  end
end
