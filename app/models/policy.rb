# frozen_string_literal: true

# Compliance policy
class Policy < ApplicationRecord
  has_many :profiles, dependent: :destroy
  has_many :hosts, through: :policy_hosts, source: :host

  belongs_to :business_objective, optional: true
  belongs_to :account

  validates :compliance_threshold, numericality: true
  validates :account, presence: true
  validates :name, presence: true, uniqueness: true
end
