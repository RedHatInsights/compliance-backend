# frozen_string_literal: true

# Represents a Insights account. An account can be composed of many users
class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :hosts, dependent: :nullify

  validates :account_number, presence: true
end
