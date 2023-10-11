# frozen_string_literal: true

module V2
  # JSON API serialization for Policies
  class PolicySerializer < V2::ApplicationSerializer
    attributes :name,
               :description,
               :compliance_threshold,
               :total_host_count,
               :test_result_host_count,
               :compliant_host_count,
               :unsupported_host_count
  end
end
