# frozen_string_literal: true

# JSON serialization for SupportedProfile
class SupportedProfileSerializer < ApplicationSerializer
  attributes :title, :description, :ref_id, :security_guide_id, :security_guide_version,
             :os_major_version, :os_minor_versions
end
