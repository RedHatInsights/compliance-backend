# frozen_string_literal: true

module V2
  # JSON API serialization for Profiles
  class ProfileSerializer < V2::ApplicationSerializer
    attributes :ref_id, :title, :description
  end
end
