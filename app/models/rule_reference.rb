# frozen_string_literal: true

# Models rule references
class RuleReference < ApplicationRecord
  scoped_search on: %i[href label]
  has_many :rule_references_rules
  has_many :rules, through: :rule_references_rules

  validates :label, presence: true, uniqueness: { scope: :href, message: 'and href combination already taken' }

  def self.from_oscap_objects(oscap_references)
    oscap_references.map do |oscap_reference|
      find_or_initialize_by(oscap_reference)
    end
  end
end
