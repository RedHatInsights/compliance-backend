class CreateSecurityGuidesV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :security_guides_v2, id: :uuid do |t|
      t.string :ref_id
      t.integer :os_major_version
      t.string :title
      t.text :description
      t.string :version
      t.string :package_name

      t.timestamps
    end

    add_index :security_guides_v2, [:ref_id, :version], unique: true, name: 'index_security_guides_v2_on_ref_id_and_version'
  end
end
