# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Profile
class ProfileSerializer
  include FastJsonapi::ObjectSerializer
  set_type :profile
  belongs_to :account
  belongs_to :benchmark
  belongs_to :business_objective
  belongs_to :parent_profile, record_type: :profile
  attributes :name, :ref_id, :description, :score, :parent_profile_id,
             :external, :compliance_threshold, :os_major_version
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
  attribute :business_objective do |profile|
    profile.business_objective&.title
  end
end
