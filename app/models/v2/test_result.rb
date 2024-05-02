# frozen_string_literal: true

module V2
  # Class representing a result of a compliance scan
  class TestResult < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_test_results
    self.primary_key = :id

    belongs_to :system, class_name: 'V2::System', optional: true
    belongs_to :tailoring, class_name: 'V2::Tailoring'

    has_one :policy, class_name: 'V2::Policy', through: :tailoring
    has_one :security_guide, class_name: 'V2::SecurityGuide', through: :tailoring
  end
end
