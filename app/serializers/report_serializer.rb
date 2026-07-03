# frozen_string_literal: true

# JSON serialization for Reports
class ReportSerializer < ApplicationSerializer
  attributes :title, :description, :business_objective, :compliance_threshold

  derived_attribute :os_major_version, security_guide: [:os_major_version]
  derived_attribute :profile_title, profile: [:title]
  derived_attribute :ref_id, profile: [:ref_id]

  aggregated_attribute :all_systems_exposed, :reporting_and_non_reporting_systems, Report::ALL_SYSTEMS_EXPOSED
  aggregated_attribute :percent_compliant, :reporting_and_non_reporting_systems, Report::PERCENT_COMPLIANT
  aggregated_attribute :assigned_system_count, :reporting_and_non_reporting_systems, Report::SYSTEM_COUNT
  aggregated_attribute :compliant_system_count, :reporting_and_non_reporting_systems, Report::COMPLIANT_SYSTEM_COUNT
  aggregated_attribute :unsupported_system_count, :reporting_and_non_reporting_systems,
                       Report::UNSUPPORTED_SYSTEM_COUNT
  aggregated_attribute :reported_system_count, :reporting_and_non_reporting_systems,
                       Report::REPORTED_SYSTEM_COUNT
  aggregated_attribute :never_reported_system_count, :reporting_and_non_reporting_systems,
                       Report::NEVER_REPORTED_SYSTEM_COUNT
end
