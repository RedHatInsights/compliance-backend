# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Profile
class ProfileSerializer
  include FastJsonapi::ObjectSerializer
  set_type :profile
  belongs_to :account
  belongs_to :benchmark
  belongs_to :parent_profile, record_type: :profile
  has_many :rules
  has_many :hosts do |profile|
    if profile.policy
      profile.policy.hosts
    else
      # external profile
      profile.test_result_hosts
    end
  end
  has_many :test_results
  attributes :ref_id, :score, :parent_profile_id,
             :external, :compliance_threshold, :os_major_version,
             :os_version, :policy_profile_id
  attribute :os_minor_version, if: proc { Settings.feature_133_os_tailoring }
  attribute :parent_profile_ref_id do |profile|
    profile.parent_profile&.ref_id
  end

  attribute :name do |profile|
    profile.policy&.name || profile.name
  end

  attribute :description do |profile|
    profile.policy&.description || profile.description
  end

  attribute :canonical, &:canonical?
  attribute :tailored, &:tailored?
  attribute :total_host_count
  attribute :ssg_version
  attribute :compliant_host_count
  attribute :test_result_host_count
  attribute :unsupported_host_count
  attribute :business_objective do |profile|
    profile&.policy&.business_objective&.title
  end
  attribute :policy_type
end
