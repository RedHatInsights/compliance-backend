# frozen_string_literal: true

# JSON serialization for an OpenSCAP Value
class ValueDefinitionSerializer < ApplicationSerializer
  attributes :ref_id, :title, :description, :value_type, :default_value
end
