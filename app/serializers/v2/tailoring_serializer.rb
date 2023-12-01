# frozen_string_literal: true

module V2
  # JSON API serialization for an OpenSCAP Profile tailoring
  class TailoringSerializer < V2::ApplicationSerializer
    attributes :profile_id
    attributes :os_minor_version
    attributes :value_overrides

    derived_attribute :os_major_version, security_guide: [:os_major_version]
  end
end
