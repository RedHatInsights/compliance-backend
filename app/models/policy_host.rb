# frozen_string_literal: true

# Join table between Policy and Host
class PolicyHost < ApplicationRecord
  belongs_to :policy
  belongs_to :host, optional: true

  validates :policy, presence: true
  validates :host, presence: true, on: :create
  validates :host_id, presence: true, uniqueness: { scope: :policy }

  def self.import_from_policy(policy_id, host_ids)
    import(host_ids.map do |host_id|
      { host_id: host_id, policy_id: policy_id }
    end)
  end
end
