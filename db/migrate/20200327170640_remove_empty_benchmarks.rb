class RemoveEmptyBenchmarks < ActiveRecord::Migration[5.2]
  def up
    # Removed so we're able to change the table name of Benchmarks
    # ::Xccdf::Benchmark.transaction do
    #   empty_benchmarks = ::Xccdf::Benchmark.where.not(
    #     id: Profile.select(:benchmark_id).distinct
    #   )
    #   empty_benchmarks.each do |empty_benchmark|
    #     empty_benchmark.rules.delete_all
    #   end
    #   empty_benchmarks.delete_all
    # end
  end

  def down
  end
end
