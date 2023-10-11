# frozen_string_literal: true

module V2
  # Host representation in insights compliance backend. Most of the times
  # these hosts will also show up in the insights-platform host inventory.
  class System < ApplicationRecord
    self.table_name = 'inventory.hosts'
    self.primary_key = 'id'

    has_many :policy_systems, dependent: :destroy, foreign_key: 'host_id'
    has_many :policies, through: :policy_systems, source: :policy
    include SystemLike
  end

end
