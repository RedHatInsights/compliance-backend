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

  class << self
    def find_from_oscap(oscap_references)
      oscap_references.inject(where('1=0')) do |rel, reference|
        rel.or(where(href: reference.href, label: reference.label))
      end
    end

    def from_openscap_parser(op_rule_reference)
      find_or_initialize_by(
        href: op_rule_reference.href,
        label: op_rule_reference.label
      )
    end

    def new_from_openscap_parser(op_rule_references)
      preexisting_rule_references = ::RuleReference.where(
        href: op_rule_references.map(&:href),
        label: op_rule_references.map(&:label)
      ).pluck(:href, :label)
      op_rule_references.reject do |rule_reference|
        preexisting_rule_references.include?([rule_reference.href,
                                              rule_reference.label])
      end
    end
  end
end
