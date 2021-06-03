# frozen_string_literal: true

# JSON API serialization for a BusinessObjective
class BusinessObjectiveSerializer < ApplicationSerializer
  attributes :title
  has_many :profiles
end
