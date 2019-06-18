# frozen_string_literal: true

# Business objectives are arbitrary strings to tag profiles in the UI
class BusinessObjective < ApplicationRecord
  has_many :profiles, dependent: :destroy
  validates :title, presence: true
end
