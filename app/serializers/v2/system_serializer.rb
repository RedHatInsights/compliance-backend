# frozen_string_literal: true

module V2
  # JSON serialization for Systems
  class SystemSerializer < V2::ApplicationSerializer
    attributes :display_name, :groups, :culled_timestamp,
               :stale_timestamp, :stale_warning_timestamp, :updated, :insights_id, :tags

    derived_attribute :os_major_version, V2::System::OS_MAJOR_VERSION
    derived_attribute :os_minor_version, V2::System::OS_MINOR_VERSION

    weak_attribute :compliant, :reports, reports: [:compliance_threshold], v2_test_results: [:score]
    weak_attribute :last_scanned, :reports, v2_test_results: [:end_time]
    weak_attribute :failed_rule_count, :reports, v2_test_results: [:failed_rule_count]

    aggregated_attribute :policies, :policies, -> { V2::System::POLICIES }
  end
end
