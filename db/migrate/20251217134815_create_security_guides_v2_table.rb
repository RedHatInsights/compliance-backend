class CreateSecurityGuidesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :security_guides_v2, id: :uuid do |t|
      t.string :ref_id, null: true
      t.integer :os_major_version, null: true
      t.string :title, null: true
      t.text :description, null: true
      t.string :version, null: true
      t.string :package_name

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO security_guides_v2 (id, ref_id, os_major_version, title, description, version, package_name, created_at, updated_at)
      SELECT id, ref_id, os_major_version, title, description, version, package_name, created_at, updated_at
      FROM security_guides;
    SQL

    change_column_null :security_guides_v2, :ref_id, false
    change_column_null :security_guides_v2, :os_major_version, false
    change_column_null :security_guides_v2, :title, false
    change_column_null :security_guides_v2, :description, false
    change_column_null :security_guides_v2, :version, false
    change_column_null :security_guides_v2, :created_at, false
    change_column_null :security_guides_v2, :updated_at, false

    add_index :security_guides_v2, [:ref_id, :version], unique: true, name: 'index_security_guides_v2_on_ref_id_and_version'
  end

  def down
    drop_table :security_guides_v2
  end
end
