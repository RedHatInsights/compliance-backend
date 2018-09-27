# frozen_string_literal: true

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  has_many :rule_results, dependent: :destroy
  has_many :rules, through: :rule_results, source: :rule

  validates :name, presence: true, uniqueness: true
end
