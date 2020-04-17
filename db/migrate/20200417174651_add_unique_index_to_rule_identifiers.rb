class AddUniqueIndexToRuleIdentifiers < ActiveRecord::Migration[5.2]
  def change
    add_index(:rule_identifiers, %i[label system rule_id], unique: true)
  end
end
