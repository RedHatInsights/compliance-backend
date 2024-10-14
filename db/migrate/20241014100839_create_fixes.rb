class CreateFixes < ActiveRecord::Migration[7.1]
  def change
    create_table :fixes, id: :uuid do |t|
      t.string :strategy
      t.string :disruption
      t.string :complexity
      t.string :system
      t.text :text
      t.references :rule, type: :uuid, index: true, null: false

      t.timestamps null: true
    end

    add_index :fixes, :system
    add_index :fixes, %i[rule_id system], unique: true
  end
end
