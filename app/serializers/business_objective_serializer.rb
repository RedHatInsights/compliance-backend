# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Profile
class BusinessObjectiveSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :title
end
