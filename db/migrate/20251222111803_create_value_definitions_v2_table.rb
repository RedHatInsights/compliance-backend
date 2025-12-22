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
      t.references :security_guide, type: :uuid, null: false

      t.timestamps precision: nil
    end

    add_index :value_definitions_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_value_definitions_v2_on_ref_id_and_security_guide_id'

    execute <<-SQL
      INSERT INTO value_definitions_v2 (id, ref_id, title, description, value_type, default_value, lower_bound, upper_bound, security_guide_id, created_at, updated_at)
      SELECT id, ref_id, title, description, value_type, default_value, lower_bound, upper_bound, security_guide_id, NOW(), NOW()
      FROM v2_value_definitions;
    SQL
  end

  def down
    drop_table :value_definitions_v2
  end
end
