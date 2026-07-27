# frozen_string_literal: true

# Model link between Report and System
class ReportSystem < ApplicationRecord
  # Necessary explicit primary key, since ReportSystem is backed by a view
  self.primary_key = :id

  belongs_to :report, class_name: 'Report'
  belongs_to :system, class_name: 'System'
end
