# frozen_string_literal: true

module V2
  # JSON serialization base class
  class ApplicationSerializer < Panko::Serializer
    attributes :id, :type

    def type
      object.model_name.element
    end
  end
end
