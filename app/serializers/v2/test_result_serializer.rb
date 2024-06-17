# frozen_string_literal: true

module V2
  # JSON serialization for Test Results
  class TestResultSerializer < V2::ApplicationSerializer
    attributes :end_time, :failed_rule_count, :supported

    derived_attribute :display_name, system: [:display_name]
    derived_attribute :groups, system: [:groups]
    derived_attribute :tags, system: [:tags]
    derived_attribute :os_major_version, system: [:system_profile]
    derived_attribute :os_minor_version, system: [:system_profile]
    derived_attribute :compliant, :score, report: [:compliance_threshold]
    derived_attribute :system_id, :system_id
    derived_attribute :security_guide_version, security_guide: [:version]
  end
end
