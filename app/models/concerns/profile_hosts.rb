# frozen_string_literal: true

# Methods that are related to a profile's hosts
module ProfileHosts
  extend ActiveSupport::Concern

  included do
    has_many :test_results, dependent: :destroy
    has_many :test_result_hosts, -> { distinct },
             through: :test_results, source: :host
    has_many :rule_results, through: :test_results
    has_many :policy_hosts, through: :policy_object
    has_many :assigned_hosts, through: :policy_hosts, source: :host
    has_many :hosts, through: :test_results
  end
end
