# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Benchmark
class BenchmarkSerializer
  include FastJsonapi::ObjectSerializer
  attributes :ref_id, :title, :version, :description
end
