# frozen_string_literal: true

# JSON API serialization for a BusinessObjective
class BusinessObjectiveSerializer
  include JSONAPI::Serializer
  attributes :title
  has_many :profiles
end
