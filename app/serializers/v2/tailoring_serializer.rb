# frozen_string_literal: true

module V2
  # JSON API serialization for an OpenSCAP Profile tailoring
  class TailoringSerializer < V2::ApplicationSerializer
    attributes :profile_id
    attributes :policy_id
    attributes :os_minor_version

    derived_attribute :os_major_version, security_guide: [:os_major_version]
    derived_attribute :value_overrides, profile: [:value_overrides]
  end
end
