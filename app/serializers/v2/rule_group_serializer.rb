# frozen_string_literal: true

module V2
  # JSON serialization for an OpenSCAP Rule Group
  class RuleGroupSerializer < V2::ApplicationSerializer
    attributes :ref_id, :title, :rationale, :description, :precedence
  end
end
