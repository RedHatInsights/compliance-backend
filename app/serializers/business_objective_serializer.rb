# frozen_string_literal: true

# JSON API serialization for a BusinessObjective
class BusinessObjectiveSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title
  has_many :profiles
end
