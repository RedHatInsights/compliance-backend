# frozen_string_literal: true

# JSON API serialization for an OpenSCAP RuleResult
class RuleResultSerializer < ApplicationSerializer
  attributes :result
  belongs_to :host
  belongs_to :rule
end
