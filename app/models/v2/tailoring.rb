# frozen_string_literal: true

module V2
  # Model for profile tailoring
  class Tailoring < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :tailorings
    self.primary_key = :id

    belongs_to :policy, class_name: 'V2::Policy'
    belongs_to :profile, class_name: 'V2::Profile'
    has_one :security_guide, through: :profile, class_name: 'V2::SecurityGuide'
    has_one :account, through: :policy, class_name: 'V2::Account'
    has_many :tailoring_rules, class_name: 'V2::TailoringRule', dependent: :destroy
    has_many :rules, class_name: 'V2::Rule', through: :tailoring_rules

    validates :policy, presence: true
    validates :profile, presence: true
    validates :os_minor_version, numericality: { greater_than_or_equal_to: 0 }
  end
end
