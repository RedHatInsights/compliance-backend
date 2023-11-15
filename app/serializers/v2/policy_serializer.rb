# frozen_string_literal: true

module V2
  # JSON serialization for Policies
  class PolicySerializer < V2::ApplicationSerializer
    attributes :title, :description, :business_objective, :compliance_threshold, :host_count

    derived_attribute :os_major_version, security_guide: [:ref_id]
    derived_attribute :profile_title, profile: [:title]
    derived_attribute :ref_id, profile: [:ref_id]
  end
end
