# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  include HostSearching

  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results, source: :rule
  has_many :policy_hosts, dependent: :destroy
  has_many :test_results, dependent: :destroy
  include SystemLike

  has_many :test_result_profiles, through: :test_results, source: :profile
  has_many :policies, through: :policy_hosts
  has_many :assigned_profiles, through: :policies, source: :profiles

  validates :name, presence: true
  validates :account, presence: true
  def readonly?
    true
  end

  alias destroy save
  alias delete save

  def all_profiles
    Profile.where(id: assigned_profiles)
           .or(Profile.where(id: test_result_profiles))
           .distinct
  end
end
