class CreateV1BenchmarksView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_benchmarks
  end
end
