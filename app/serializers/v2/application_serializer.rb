# frozen_string_literal: true

# JSON serializer that overrides the JSONAPI::Serializer's relationship_hash
# This highly depends on the jsonapi-serializer gem and should be adjusted
# if this dependency gets changed or updated
module V2
  class ApplicationSerializer
    include ::JSONAPI::Serializer
  end
end
