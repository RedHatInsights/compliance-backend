# frozen_string_literal: true

# JSON serialization for Security Guides
class SecurityGuideSerializer < ApplicationSerializer
  attributes :ref_id, :title, :version, :description, :os_major_version
end
