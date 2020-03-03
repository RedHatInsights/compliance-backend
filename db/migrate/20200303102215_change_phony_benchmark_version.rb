class ChangePhonyBenchmarkVersion < ActiveRecord::Migration[5.2]
  # The `.latest` method of ::Xccdf::Benchmark is using Gem::Version, which
  # expects the version to have the same versioning syntax as a gemspec.
  def up
    ::Xccdf::Benchmark.find_by(ref_id: 'phony_ref_id').update!(version: '0.0.0')
  end

  def down
  end
end
