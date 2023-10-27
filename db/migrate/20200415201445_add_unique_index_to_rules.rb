class AddUniqueIndexToRules < ActiveRecord::Migration[5.2]
  def up
    add_index(:rules, %i[ref_id benchmark_id], unique: true)
  end

  def down
    remove_index(:rules, %i[ref_id benchmark_id])
  end
end
