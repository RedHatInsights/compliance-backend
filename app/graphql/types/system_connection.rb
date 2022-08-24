# frozen_string_literal: true

module Types
  # Contains fields and methods related with system connection fields
  class SystemConnection < BaseConnection
    field :os_versions, GraphQL::Types::JSON, null: false
    field :tags, GraphQL::Types::JSON, null: false

    def os_versions
      object.items.limit(nil).available_os_versions
    end

    def tags
      context[:wide_scope].available_tags
    end
  end
end
