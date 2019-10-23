class AddBenchmarkIdToRule < ActiveRecord::Migration[5.2]
  def change
    add_column :rules, :benchmark_id, :uuid, null: false
  end
end
