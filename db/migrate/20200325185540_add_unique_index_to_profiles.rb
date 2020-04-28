class AddUniqueIndexToProfiles < ActiveRecord::Migration[5.2]
  def up
    DuplicateProfileResolver.run!

    add_index(:profiles, %i[ref_id account_id benchmark_id], unique: true)
  end

  def down
    remove_index(:profiles, %i[ref_id account_id benchmark_id])
  end
end
