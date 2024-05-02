# frozen_string_literal: true

module V2
  # JSON serialization for Reports
  class ReportSerializer < V2::ApplicationSerializer
    attributes :title, :description, :business_objective, :compliance_threshold

    derived_attribute :os_major_version, security_guide: [:os_major_version]
    derived_attribute :profile_title, profile: [:title]
    derived_attribute :ref_id, profile: [:ref_id]
    derived_attribute :all_systems_exposed, :total_system_count

    aggregated_attribute :assigned_system_count, :assigned_systems, V2::Report::SYSTEM_COUNT
    aggregated_attribute :compliant_system_count, :systems, V2::Report::COMPLIANT_SYSTEM_COUNT
    aggregated_attribute :unsupported_system_count, :systems, V2::Report::UNSUPPORTED_SYSTEM_COUNT
    aggregated_attribute :result_system_count, :systems, V2::Report::SYSTEM_COUNT
  end
end
