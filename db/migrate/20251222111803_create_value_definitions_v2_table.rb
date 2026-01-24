class CreateValueDefinitionsV2Table < ActiveRecord::Migration[8.0]
  def up
    create_table :value_definitions_v2, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.text :description
      t.string :value_type
      t.string :default_value
      t.decimal :lower_bound
      t.decimal :upper_bound
      t.references :security_guide, type: :uuid, index: false, null: true

      t.timestamps precision: nil, null: true
    end

    execute <<-SQL
      INSERT INTO value_definitions_v2 (id, ref_id, title, description, value_type, default_value, lower_bound, upper_bound, security_guide_id, created_at, updated_at)
      SELECT id, ref_id, title, description, value_type, default_value, lower_bound, upper_bound, security_guide_id, NOW(), NOW()
      FROM v2_value_definitions;
    SQL

    change_column_null :value_definitions_v2, :security_guide_id, false
    change_column_null :value_definitions_v2, :created_at, false
    change_column_null :value_definitions_v2, :updated_at, false

    add_index :value_definitions_v2, [:security_guide_id], name: 'index_value_definitions_v2_on_security_guide_id'
    add_index :value_definitions_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_value_definitions_v2_on_ref_id_and_security_guide_id'
  end

  def down
    drop_table :value_definitions_v2
  end
end
