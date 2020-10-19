# frozen_string_literal: true

# Business objectives are arbitrary strings to tag policies in the UI
class BusinessObjective < ApplicationRecord
  has_many :policies, dependent: :nullify
  has_many :profiles, through: :policies
  has_many :accounts, through: :policies

  validates :title, presence: true

  scope :in_account, lambda { |account_or_account_id|
    joins(:accounts).where(accounts: { id: account_or_account_id }).distinct
  }

  scope :without_policies, lambda {
    includes(:policies).where(policies: { id: nil })
  }

  def self.from_title(title)
    find_or_create_by(title: title) if title
  end
end
