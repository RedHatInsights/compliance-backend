# frozen_string_literal: true

module Types
  # Contains fields and methods related with GraphQL connection fields
  class BaseConnection < Types::BaseObject
    # add `nodes` and `pageInfo` fields, as well as `edge_type(...)` and `node_nullable(...)` overrides
    include GraphQL::Types::Relay::ConnectionBehaviors

    field :total_count, Integer, null: false

    def total_count
      # Count the whole collection using a single column and not the whole table. This column
      # by default is the primary key of the table, however, in certain cases using a different
      # indexed column might produce faster results without even accessing the table.
      object.items.except(:select).select(object.items.base_class.count_by).count
    end
  end
end
