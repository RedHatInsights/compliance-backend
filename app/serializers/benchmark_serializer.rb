# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Benchmark
class BenchmarkSerializer
  include FastJsonapi::ObjectSerializer
  attributes :ref_id, :title, :version, :description, :os_major_version
  has_many :rules
  has_many :profiles do |benchmark|
    Pundit.policy_scope(User.current, Profile).where(benchmark: benchmark)
  end
end
