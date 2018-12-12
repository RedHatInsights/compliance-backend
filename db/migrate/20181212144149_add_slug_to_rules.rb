class AddSlugToRules < ActiveRecord::Migration[5.2]
  def change
    add_column :rules, :slug, :string
    add_index :rules, :slug, unique: true
  end
end
