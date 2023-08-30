# frozen_string_literal: true

module V2
  # JSON API serialization for an OpenSCAP Rule
  class RuleSerializer < ApplicationSerializer
    attributes :ref_id, :title, :rationale, :description, :severity, :precedence
  end
end
