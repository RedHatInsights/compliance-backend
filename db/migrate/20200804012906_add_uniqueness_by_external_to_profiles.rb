class AddUniquenessByExternalToProfiles < ActiveRecord::Migration[5.2]
  def up
    remove_index(:profiles, %i[ref_id account_id benchmark_id])
    add_index(:profiles, %i[ref_id account_id benchmark_id external], unique: true, name: 'uniqueness')
  end

  def down
    remove_index(:profiles, %i[ref_id account_id benchmark_id external])
    add_index(:profiles, %i[ref_id account_id benchmark_id], unique: true)
  end
end
