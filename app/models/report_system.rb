# frozen_string_literal: true

# Model link between Report and System
class ReportSystem < ApplicationRecord
  # Necessary explicit primary key, since ReportSystem is backed by a view
  self.primary_key = :id

  belongs_to :report, class_name: 'Report'
  belongs_to :system, class_name: 'System'

  validates :policy_id, presence: true
  validates :system_id, presence: true, uniqueness: { scope: :policy_id }
  validate :system_supported?, on: :create
end
