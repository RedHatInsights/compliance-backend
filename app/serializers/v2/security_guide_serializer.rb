# frozen_string_literal: true

module V2
  class SecurityGuideSerializer < V2::ApplicationSerializer
    attributes :ref_id, :title, :version, :description, :os_major_version
  end
end
