# frozen_string_literal: true

module V2
  # Model link between Policy and System
  class PolicySystem < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :policy_systems
    self.primary_key = :id

    belongs_to :policy, class_name: 'V2::Policy'
    belongs_to :system, class_name: 'V2::System'
  end
end
