# frozen_string_literal: true

# Join table between Policy and Host
class PolicyHost < ApplicationRecord
  belongs_to :policy
  belongs_to :host

  validates :policy, presence: true
  validates :host, presence: true, uniqueness: { scope: :policy }
end
