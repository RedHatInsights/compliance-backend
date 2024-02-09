# frozen_string_literal: true

module V2
  # Model link between Policy and System
  class PolicySystem < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :policy_hosts

    belongs_to :policy, class_name: 'V2::Policy'
    belongs_to :system, class_name: 'V2::System', foreign_key: :host_id, inverse_of: :policy_systems
  end
end
