class CreateSecurityGuidesV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :security_guides_v2, id: :uuid do |t|
      t.string :ref_id
      t.integer :os_major_version
      t.string :title
      t.text :description
      t.string :version
      t.string :package_name

      t.timestamps precision: nil
    end

    add_index :security_guides_v2, [:ref_id, :version], unique: true, name: 'index_security_guides_v2_on_ref_id_and_version'

    execute <<-SQL
      INSERT INTO security_guides_v2 (id, ref_id, os_major_version, title, description, version, package_name, created_at, updated_at)
      SELECT id, ref_id, os_major_version, title, description, version, package_name, created_at, updated_at
      FROM security_guides;
    SQL
  end

  def down
    drop_table :security_guides_v2
  end
end
