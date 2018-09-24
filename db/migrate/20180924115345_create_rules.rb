class CreateRules < ActiveRecord::Migration[5.2]
  def change
    create_table :rules, id: :uuid do |t|
      t.string :ref_id
      t.boolean :supported
      t.string :title
      t.string :severity
      t.text :description
      t.text :rationale

      t.timestamps
    end
    add_index :rules, :ref_id
  end
end
