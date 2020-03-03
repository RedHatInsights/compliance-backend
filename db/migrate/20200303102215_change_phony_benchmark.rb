class ChangePhonyBenchmark < ActiveRecord::Migration[5.2]
  def up
    ::Xccdf::Benchmark.find_by(ref_id: 'phony_ref_id').update(version: '0.0.0')
  end

  def down
    ::Xccdf::Benchmark.find_by(ref_id: 'phony_ref_id').update(version: 'v0.0.0')
  end
end
