class AddUniqueIndexToRuleReferences < ActiveRecord::Migration[5.2]
  def up
    DuplicateRuleReferenceResolver.run!

    add_index(:rule_references, %i[href label], unique: true)
  end

  def down
    remove_index(:rule_references, %i[href label])
  end
end
