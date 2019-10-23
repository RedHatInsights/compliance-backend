class AddBenchmarkIdToProfile < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :benchmark_id, :uuid, null: false
  end
end
