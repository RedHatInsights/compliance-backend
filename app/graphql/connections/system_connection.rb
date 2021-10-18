# frozen_string_literal: true

module Connections
  # Contains fields and methods related with system connection fields
  class SystemConnection < BaseConnection
    field :os_versions, [::Types::OperatingSystem], null: false
    field :tags, [::Types::Tag], null: false

    def os_versions
      object.nodes.limit(nil).available_os_versions
    end

    def tags
      object.nodes.limit(nil).available_tags
    end
  end
end
