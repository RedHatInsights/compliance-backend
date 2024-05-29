# frozen_string_literal: true

module V2
  # Model link between Report and System
  class ReportSystem < ApplicationRecord
    self.table_name = :report_systems
    self.primary_key = :id

    belongs_to :report, class_name: 'V2::Report'
    belongs_to :system, class_name: 'V2::System'

    validates :policy_id, presence: true
    validates :system_id, presence: true, uniqueness: { scope: :policy_id }
    validate :system_supported?, on: :create
  end
end
