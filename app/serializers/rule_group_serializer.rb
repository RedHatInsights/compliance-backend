# frozen_string_literal: true

# JSON API serialization for an OpenSCAP RuleGroup
class RuleGroupSerializer < ApplicationSerializer
  attributes :ref_id, :title, :description, :rationale
  belongs_to :benchmark
  has_many :profiles
end
