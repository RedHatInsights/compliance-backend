class CreateValueDefinitionsV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :value_definitions_v2, id: :uuid do |t|
      t.string :ref_id
      t.string :title
      t.text :description
      t.string :value_type
      t.string :default_value
      t.decimal :lower_bound
      t.decimal :upper_bound
      t.uuid :security_guide_id, null: false

      t.timestamps
    end

    add_index :value_definitions_v2, [:security_guide_id], name: 'index_value_definitions_v2_on_security_guide_id'
    add_index :value_definitions_v2, [:ref_id, :security_guide_id], unique: true, name: 'index_value_definitions_v2_on_ref_id_and_security_guide_id'
  end
end
