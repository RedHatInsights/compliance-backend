# frozen_string_literal: true

module V2
  # JSON serialization for SupportedProfile
  class SupportedProfileSerializer < V2::ApplicationSerializer
    attributes :title, :ref_id, :security_guide_version, :os_major_version, :os_minor_versions
  end
end
