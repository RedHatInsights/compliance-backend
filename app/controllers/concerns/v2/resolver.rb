# frozen_string_literal: true

module V2
  # Concern for resolving database resources
  module Resolver
    extend ActiveSupport::Concern

    private

    # Building the query that returns all the required data for serialization
    def expand_resource
      # Join with the parents assumed from the route
      scope = join_parents(pundit_scope, permitted_params[:parents])
      # Join with the additional 1:1 relationships required by the serializer, select only the
      # dependencies that are really necessary for the rendering.
      join_aggregated(join_associated(scope)).select(*select_fields)
    end

    # Reduce through all the associations of the `relation` and join+scope them or return the
    # `relation˙ untouched if it does not have any associations.
    def join_parents(relation, associations)
      associations.to_a.reduce(relation) do |scope, association|
        ref = scope.reflect_on_association(association)
        klass = ref.klass

        scope.joins(association)
             .where(association => { klass.primary_key => permitted_params[ref.foreign_key] })
             .where(pundit_subquery(association))
      end
    end

    # Select the 1:1 associations that can be satisfied without any additional WHERE clause,
    # then join them with the relation.
    def join_associated(relation)
      # Do not join with the already joined parents assumed from the (nested) route
      associations = dependencies.keys.excluding(*permitted_params[:parents]).compact
      relation.where.associated(*associations)
    end

    # Self-join with the requested aggregations built using 1:n associations, also select
    # the aggregated field from the self-joined subquery.
    def join_aggregated(relation)
      aggregations.reduce(relation) do |scope, (association, aggregation)|
        scope.joins(subquery_fragment(association, aggregation))
             .select(aggregation.alias)
      end
    end

    # Builds a subquery with the `resource` left outer joined with the `association`, grouped
    # by the primary key of the `resource` and returning the result with the `aggregation`.
    # This subquery is then further self-joined with the `resource` and the joining fragment
    # is extracted from the arel tree.
    #
    # The resulting fragment ends up in the following format:
    # ```
    # INNER JOIN (
    #   SELECT "resource"."id", AGG("association"."XY") FROM "resource" LEFT OUTER JOIN "association" ...
    # ) "aggregate_association" ON "aggregate_association"."id" = "resource"."id";
    # ```
    #
    def subquery_fragment(association, aggregation)
      sq = resource.left_outer_joins(association)
                   .group(resource.primary_key)
                   .select(resource.primary_key, aggregation)
      resource.arel_join_fragment(sq.arel.as(association.to_s))
    end

    # Iterate through the (nested) fields to be selected and set their names accordingly
    # so it is understood by SQL. Furthermore, alias any field that is coming from a joined
    # table to avoid any possible hash key collision.
    def select_fields
      dependencies.flat_map do |(association, fields)|
        fields.map do |field|
          if association
            "#{association}.#{field} AS #{association}__#{field}"
          else
            # FIXME: this is just temporary until we figure out aggregations as they will be also arel-based
            field.is_a?(ApplicationRecord::AN::Node) ? field.to_sql : [resource.table_name, field].join('.')
          end
        end
      end
    end

    # Get the list of dependent (relations => [fields]) to be selected from the serializer and append the
    # list of additional fields required to render the response, usually RBAC related.
    def dependencies
      @dependencies ||= begin
        deps = serializer.dependencies(permitted_params[:parents], resource.one_to_one)
        deps[nil] += extra_fields
        deps
      end
    end

    # Retrieve the list of aggregations on any one-to-many associations specified by the serializer
    def aggregations
      @aggregations ||= serializer.aggregations(permitted_params[:parents], resource.one_to_many)
    end

    def pundit_subquery(association)
      ref = resource.reflect_on_association(association)
      klass = ref.klass

      { association => { klass.primary_key => Pundit.policy_scope(current_user, klass) } }
    end
  end
end
