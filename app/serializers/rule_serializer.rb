# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Rule
class RuleSerializer < ApplicationSerializer
  attributes :ref_id, :remediation_issue_id, :title, :rationale, :description,
             :severity, :slug, :values, :precedence
  belongs_to :benchmark

  has_many :profiles do |rule|
    # The right way to do this would be to use the pundit policy below:
    # Pundit.policy_scope(User.current, rule.profiles)
    #
    # Unfortunately, it generates an N+1, while we already have the profiles preloaded,
    # therefore, it should be faster to just filter out the profiles that are unwanted
    rule.profiles.select do |profile|
      profile.account_id.nil? || profile.account_id == User.current.account.id
    end
  end

  has_one :rule_identifier, serializer: RuleIdentifierSerializer do |record|
    OpenStruct.new(record.identifier.merge(id: SecureRandom.uuid)) if record.identifier.present?
  end
end
