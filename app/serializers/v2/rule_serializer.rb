# frozen_string_literal: true

module V2
  # JSON serialization for an OpenSCAP Rule
  class RuleSerializer < V2::ApplicationSerializer
    attributes :ref_id, :title, :rationale, :description, :severity, :precedence
  end
end
