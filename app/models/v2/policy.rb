# frozen_string_literal: true

module V2
  # Compliance policy
  class Policy < ApplicationRecord
    has_many :policy_systems, dependent: :delete_all
    has_many :systems, through: :policy_systems, source: :system, foreign_key: 'host_id'

    belongs_to :account
    delegate :org_id, to: :account

    validates :account, presence: true
    validates :name, presence: true
    validates :compliance_threshold, numericality: true
  end
end
