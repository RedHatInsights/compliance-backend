# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  scoped_search on: %i[id name]
  has_many :rule_results, dependent: :destroy
  has_many :rules, through: :rule_results, source: :rule
  has_many :profile_hosts, dependent: :destroy
  has_many :profiles, through: :profile_hosts, source: :profile
  belongs_to :account, optional: true

  validates :name, presence: true, uniqueness: { scope: :account_id }
end
