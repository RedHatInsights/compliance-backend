# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  include HostSearching

  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results, source: :rule
  has_many :profile_hosts, dependent: :destroy
  has_many :policy_hosts, dependent: :destroy
  has_many :test_results, dependent: :destroy
  include SystemLike

  has_many :profile_host_profiles, through: :profile_hosts, source: :profile
  has_many :test_result_profiles, through: :test_results, source: :profile
  has_many :policies, through: :policy_hosts
  has_many :assigned_profiles, through: :policies, source: :profiles

  validates :name, presence: true
  validates :account, presence: true

  def all_profiles
    Profile.where(id: assigned_profiles)
           .or(Profile.where(id: test_result_profiles))
           .distinct
  end

  def update_from_inventory_host!(i_host)
    update!({ name: i_host['display_name'],
              os_major_version: i_host['os_major_version'],
              os_minor_version: i_host['os_minor_version'] }.compact)
  end

  def os_version
    "#{os_major_version}.#{os_minor_version}"
  end
end
