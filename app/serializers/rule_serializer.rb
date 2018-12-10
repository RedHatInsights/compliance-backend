# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Rule
class RuleSerializer
  include FastJsonapi::ObjectSerializer
  attributes :created_at, :updated_at, :ref_id, :title, :rationale,
             :description, :severity
  attributes :total_systems_count do |rule|
    rule.hosts.count {}
  end
  attributes :affected_systems_count do |rule|
    rule.hosts.count { |host| rule.compliant?(host) }
  end
end
