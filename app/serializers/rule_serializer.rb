# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Rule
class RuleSerializer
  include FastJsonapi::ObjectSerializer
  attributes :created_at, :updated_at, :ref_id, :title, :rationale,
             :description, :severity, :slug
end
