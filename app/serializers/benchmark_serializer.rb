# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Benchmark
class BenchmarkSerializer
  include FastJsonapi::ObjectSerializer

  attributes :ref_id, :title, :version, :description, :os_major_version,
             :latest_supported_os_minor_versions
  has_many :rules do |benchmark, params|
    benchmark.rules.paginate(per_page: params[:limit], page: params[:offset])
  end
  has_many :profiles do |benchmark|
    Pundit.policy_scope(User.current, Profile).where(benchmark: benchmark)
  end
end
