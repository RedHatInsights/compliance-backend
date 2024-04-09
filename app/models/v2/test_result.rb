# frozen_string_literal: true

module V2
  # Class representing a result of a compliance scan
  class TestResult < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_test_results
    self.primary_key = :id

    belongs_to :system, optional: true
    belongs_to :tailoring
    has_one :policy, through: :tailoring
    has_one :security_guide, through: :tailoring
  end
end
