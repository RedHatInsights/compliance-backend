class AddBenchmarkIdToProfile < ActiveRecord::Migration[5.2]
  # Removed so we're able to change the table name of Benchmarks
  # PHONY_BENCHMARK = Xccdf::Benchmark.find_or_create_by!(
  #   ref_id: 'phony_ref_id',
  #   version: 'v0.0.0',
  #   title: 'phony title',
  #   description: 'phony description'
  # )

  def change
    add_column :profiles, :benchmark_id, :uuid, null: false
      # default: PHONY_BENCHMARK.id
  end
end
