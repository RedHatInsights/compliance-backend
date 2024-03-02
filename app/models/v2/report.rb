# frozen_string_literal: true

module V2
  # Model for reports
  class Report < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :reports
    self.primary_key = :id

    # To prevent an autojoin with itself, there should not be an inverse relationship specified
    belongs_to :policy, class_name: 'V2::Policy', foreign_key: :id # rubocop:disable Rails/InverseOf
    has_many :tailorings, class_name: 'V2::Tailoring', through: :policy
    has_many :systems, class_name: 'V2::System', through: :tailorings
  end
end
