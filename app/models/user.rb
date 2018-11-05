# frozen_string_literal: true

# Represents an individual Insights-Compliance user
class User < ApplicationRecord
  validates:redhat_id, uniqueness: true, presence: true
  validates :login, uniqueness: true, presence: true
  validates_associated :account_id
end
