class AddUniqueConstraintToProfileByAccount < ActiveRecord::Migration[5.2]
  def change
    add_index(:profiles , %i[account_id ref_id benchmark_id], unique: true)
  end
end
