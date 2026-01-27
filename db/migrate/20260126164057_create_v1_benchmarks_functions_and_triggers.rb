class CreateV1BenchmarksFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_benchmarks_insert
    create_function :v1_benchmarks_update
    create_trigger :v1_benchmarks_insert, on: :v1_benchmarks
    create_trigger :v1_benchmarks_update, on: :v1_benchmarks
  end
end
