# frozen_string_literal: true

# JSON serialization for an OpenSCAP Rule Group
class RuleGroupSerializer < ApplicationSerializer
  attributes :ref_id, :title, :rationale, :description, :precedence
end
