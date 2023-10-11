# frozen_string_literal: true

module V2
  class PolicySystem < ApplicationRecord
    self.table_name = 'policy_hosts'

    belongs_to :policy
    belongs_to :system, optional: true
  end
end
