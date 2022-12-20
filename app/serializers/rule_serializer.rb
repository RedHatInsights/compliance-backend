# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Rule
class RuleSerializer < ApplicationSerializer
  attributes :ref_id, :remediation_issue_id, :title, :rationale, :description,
             :severity, :slug, :values, :precedence
  belongs_to :benchmark
  has_many :profiles
  has_one :rule_identifier, serializer: RuleIdentifierSerializer do |record|
    OpenStruct.new(record.identifier.merge(id: SecureRandom.uuid)) if record.identifier.present?
  end
end
