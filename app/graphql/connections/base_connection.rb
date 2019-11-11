# frozen_string_literal: true

module Connections
  # Contains fields and methods related with GraphQL connection fields
  class BaseConnection < GraphQL::Types::Relay::BaseConnection
    field :total_count, Integer, null: false

    def total_count
      object.nodes.count
    end
  end
end
