# frozen_string_literal: true

# Stores information about rules. This comes from SCAP.
module V2
  # Model for Rules
  class Fix < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :fixes

    ANACONDA = 'urn:redhat:anaconda:pre'
    BLUEPRINT = 'urn:redhat:osbuild:blueprint'
    ANSIBLE = 'urn:xccdf:fix:script:ansible'
    IGNITION = 'urn:xccdf:fix:script:ignition'
    KUBERNETES = 'urn:xccdf:fix:script:kubernetes'
    PUPPET = 'urn:xccdf:fix:script:puppet'
    SHELL = 'urn:xccdf:fix:script:sh'

    belongs_to :rule
    has_one :security_guide, through: :rule

    def self.from_parser(obj, existing: nil, rule_id: nil, system: nil)
      record = existing || new(rule_id: rule_id, system: system)

      record.assign_attributes(strategy: obj.strategy, disruption: obj.disruption,
                               complexity: obj.complexity, text: obj.text)

      record
    end
  end
end
