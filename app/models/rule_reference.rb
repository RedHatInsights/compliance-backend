# frozen_string_literal: true

# Models rule references
class RuleReference < ApplicationRecord
  default_scope { order(:label) }
  scoped_search on: %i[href label]
  has_many :rule_references_rules, dependent: :delete_all
  has_many :rules, through: :rule_references_rules

  validates :label, presence: true,
                    uniqueness: {
                      scope: :href,
                      message: 'and href combination already taken'
                    }
  validates :href, presence: true, allow_blank: true

  def self.find_from_oscap(oscap_references)
    oscap_references.inject(where('1=0')) do |rel, reference|
      rel.or(where(reference))
    end
  end
end
