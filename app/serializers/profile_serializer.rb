class ProfileSerializer
  include FastJsonapi::ObjectSerializer
  set_type :profile
  attributes :name, :ref_id
end
