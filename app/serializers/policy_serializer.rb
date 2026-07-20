# frozen_string_literal: true

# JSON serialization for Policies
class PolicySerializer < ApplicationSerializer
  attributes :title, :description, :business_objective, :compliance_threshold

  aggregated_attribute :total_system_count, :policy_systems, Policy::TOTAL_SYSTEM_COUNT

  derived_attribute :os_major_version, security_guide: [:os_major_version]
  derived_attribute :profile_title, profile: [:title]
  derived_attribute :ref_id, profile: [:ref_id]
end
