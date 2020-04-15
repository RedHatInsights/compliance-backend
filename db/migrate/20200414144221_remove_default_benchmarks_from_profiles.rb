class RemoveDefaultBenchmarksFromProfiles < ActiveRecord::Migration[5.2]
  def up
    change_column_default :profiles, :benchmark_id, nil
  end

  def down
    phony_benchmark = Xccdf::Benchmark.find_or_create_by!(
      ref_id: 'phony_ref_id',
      version: '0.0.0',
      title: 'phony title',
      description: 'phony description'
    )

    change_column_default :profiles, :benchmark_id, phony_benchmark.id
  end
end
