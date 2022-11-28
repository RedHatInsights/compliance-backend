# frozen_string_literal: true

# JSON API serialization for a Rule Identifier
class RuleIdentifierSerializer < ApplicationSerializer
  # Fake UUID for APIv1 backwards compatibility
  set_id { SecureRandom.uuid }
  attribute :label, :system
end
