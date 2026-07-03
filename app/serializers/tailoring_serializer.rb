# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Profile tailoring
class TailoringSerializer < ApplicationSerializer
  attributes :profile_id, :os_minor_version, :value_overrides

  derived_attribute :os_major_version, security_guide: [:os_major_version]
  derived_attribute :security_guide_id, profile: [:security_guide_id]
  derived_attribute :security_guide_version, security_guide: [:version]
end
