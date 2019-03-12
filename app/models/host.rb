# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  scoped_search on: %i[id name account_id]
  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results, source: :rule
  has_many :profile_hosts, dependent: :delete_all
  include SystemLike

  has_many :profiles, through: :profile_hosts, source: :profile

  validates :name, presence: true, uniqueness: { scope: :account_id }
end
