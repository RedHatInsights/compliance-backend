# frozen_string_literal: true

# Helper methods related to graphql fields
module Fields
  extend ActiveSupport::Concern

  class_methods do
    def record_field(name, type)
      field name, type, resolver: Resolvers::Generic.for(type).record
    end

    def collection_field(name, type)
      field name, type.connection_type,
            null: false, resolver: Resolvers::Generic.for(type).collection
    end
  end
end
