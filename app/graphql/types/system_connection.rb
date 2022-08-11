# frozen_string_literal: true

module Types
  # Contains fields and methods related with system connection fields
  class SystemConnection < BaseConnection
    field :os_versions, [::Types::OperatingSystem], null: false
    field :tags, [::Types::Tag], null: false

    def os_versions
      object.items.limit(nil).available_os_versions
    end

    def tags
      object.items.limit(nil).available_tags
    end
  end
end
