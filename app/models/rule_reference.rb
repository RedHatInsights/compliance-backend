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
  validates :href, length: { minimum: 0 },
                   uniqueness: {
                     scope: :label,
                     message: 'and label combination already taken'
                   }

  def self.find_unique(references)
    arel_find(references) do |reference|
      arel_table[:href].eq(reference.href)
                       .and(arel_table[:label].eq(reference.label))
    end
  end

  def self.from_openscap_parser(op_rule_reference)
    find_or_initialize_by(
      href: op_rule_reference.href,
      label: op_rule_reference.label
    )
  end
end
