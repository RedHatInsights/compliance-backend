# frozen_string_literal: true

class TestResult < ApplicationRecord
  belongs_to :profile
  belongs_to :host
  has_many :rule_results, dependent: :delete_all

  validates :host_id, presence: true
  validates :profile_id, presence: true
end
