# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Profile
class ProfileSerializer
  include FastJsonapi::ObjectSerializer
  set_type :profile
  attributes :name, :ref_id
end
