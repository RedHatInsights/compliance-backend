# frozen_string_literal: true

# JSON API serialization for an OpenSCAP RuleResult
class RuleResultSerializer
  include FastJsonapi::ObjectSerializer
  attributes :created_at, :updated_at, :result
  belongs_to :host
  belongs_to :rule
end
