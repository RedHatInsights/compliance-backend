# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Profile
class ProfileSerializer
  include FastJsonapi::ObjectSerializer
  set_type :profile
  attributes :name, :ref_id, :description, :score, :parent_profile_id, :external
  attribute :parent_profile_ref_id do |profile|
    profile.parent_profile&.ref_id
  end
  attribute :canonical, &:canonical?
  attribute :tailored, &:tailored?
  attribute :total_host_count do |profile|
    profile.hosts.count
  end
  attribute :compliant_host_count do |profile|
    profile.hosts.count { |host| profile.compliant?(host) }
  end
end
