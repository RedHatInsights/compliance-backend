# frozen_string_literal: true

module V2
  # Concern for resolving database resources
  module Resolver
    extend ActiveSupport::Concern

    def expand_resource
      # Get the list of fields to be selected from the serializer
      fields = serializer.fields(permitted_params[:parents], resource.one_to_one)
      # Append a list of additional fields required to render the response, usually RBAC related
      fields[nil] += extra_fields

      # Join with the parents assumed from the route
      scope = join_parents(pundit_scope, permitted_params[:parents])
      # Join with the additional 1:1 relationships required by the serializer,
      # select only the fields that are really necessary for the rendering.
      join_one_to_ones(scope, fields).select(*select_fields(fields))
    end

    # Reduce through all the parents of the resource and join+scope them on the resource
    # or return with the resource untouched if not nested under other resources
    def join_parents(resource, parents)
      parents.to_a.reduce(resource) do |scope, parent|
        ref = scope.reflect_on_association(parent)
        klass = ref.klass

        scope.joins(parent)
             .where(parent => { klass.primary_key => permitted_params[ref.foreign_key] })
             .merge(Pundit.policy_scope(current_user, klass))
      end
    end

    # Select the 1:1 associations that can be satisfied without any additional WHERE clause,
    # then join them to the scope.
    def join_one_to_ones(scope, fields)
      # Do not join with the already joined parents assumed from the (nested) route
      associations = fields.keys.excluding(*permitted_params[:parents]).compact
      scope.where.associated(*associations)
    end

    # Iterate through the (nested) fields to be selected and set their names accordingly
    # so it is understood by SQL. Furthermore, alias any field that is coming from a joined
    # table to avoid any possible hash key collision.
    def select_fields(fields)
      fields.flat_map do |(association, columns)|
        columns.map do |column|
          if association
            "#{association}.#{column} AS #{association}__#{column}"
          else
            # FIXME: this is just temporary until we figure out aggregations as they will be also arel-based
            column.is_a?(ApplicationRecord::AN::Node) ? column.to_sql : [resource.table_name, column].join('.')
          end
        end
      end
    end
  end
end
