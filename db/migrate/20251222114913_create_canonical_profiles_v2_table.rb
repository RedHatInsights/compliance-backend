class CreateCanonicalProfilesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :canonical_profiles_v2, id: :uuid do |t|
      t.string :title
      t.string :ref_id
      t.string :description
      t.references :security_guide, type: :uuid, index: false, null: true
      t.boolean :upstream
      t.jsonb :value_overrides, default: {}

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO canonical_profiles_v2 (id, title, ref_id, description, security_guide_id, upstream, value_overrides, created_at, updated_at)
      SELECT id, title, ref_id, description, security_guide_id, upstream, value_overrides, created_at, updated_at
      FROM canonical_profiles;
    SQL

    change_column_null :canonical_profiles_v2, :security_guide_id, false
    change_column_null :canonical_profiles_v2, :created_at, false
    change_column_null :canonical_profiles_v2, :updated_at, false

    add_index :canonical_profiles_v2, [:title], name: 'index_canonical_profiles_v2_on_title'
    add_index :canonical_profiles_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_canonical_profiles_v2_on_ref_id_and_security_guide_id'
    add_index :canonical_profiles_v2, [:upstream], name: 'index_canonical_profiles_v2_on_upstream'
  end

  def down
    drop_table :canonical_profiles_v2
  end
end
