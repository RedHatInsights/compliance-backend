# frozen_string_literal: true

# JSON serialization for Profiles
class ProfileSerializer < ApplicationSerializer
  attributes :ref_id, :title, :description, :value_overrides
end
