class DropReferencesColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :rules, :references
  end
end
