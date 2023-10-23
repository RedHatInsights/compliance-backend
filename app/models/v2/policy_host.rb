# frozen_string_literal: true

module V2
  # Model link between Policy and Host
  class PolicyHost < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :policy_hosts

    belongs_to :policy, class_name: 'V2::Policy'
    belongs_to :host, class_name: '::Host'
  end
end
