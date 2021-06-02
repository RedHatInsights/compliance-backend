# frozen_string_literal: true

# JSON serializer that overrides the JSONAPI::Serializer's relationship_hash
# This highly depends on the jsonapi-serializer gem and should be adjusted
# if this dependency gets changed or updated
class ApplicationSerializer
  include ::JSONAPI::Serializer

  class << self
    # rubocop:disable Layout/LineLength
    def relationships_hash(record, relationships, fieldset, includes_list, params = {})
      # rubocop:enable Layout/LineLength
      return {} if params[:root_resource] != record.class

      super(record, relationships, fieldset, includes_list, params)
    end
  end
end
