# frozen_string_literal: true

module V2
  # Generic methods to be used when calling resolve_collection on our models
  module Collection
    extend ActiveSupport::Concern

    include ::TagFiltering

    included do
      private

      def resolve_collection
        scope = search(policy_scope(expand_resource))
        count = count_collection(scope)
        # If the count of records equals zero, make sure that the parents exist.
        validate_parents! if count.zero? && permitted_params[:parents]&.any?

        result = filter_by_tags(sort(scope))
        result.limit(pagination_limit).offset(pagination_offset)
      end

      def count_collection(scope)
        # Count the whole collection using a single column and not the whole table. This column
        # by default is the primary key of the table, however, in certain cases using a different
        # indexed column might produce faster results without even accessing the table.
        # Pagination is disabled when counting collection so that all returned entities are counted.
        @count_collection ||= scope.except(:select, :limit, :offset)
                                   .select(resource.base_class.count_by).count
      end

      def validate_parents!
        *parents, current = permitted_params[:parents]
        reflection = resource.reflect_on_association(current)
        join_parents(reflection.klass, parents).find(permitted_params[reflection.foreign_key])
      end

      # :nocov:
      def filter_by_tags(data)
        unless TagFiltering.tags_supported?(resource) && permitted_params[:tags]&.any?
          return data
        end

        tags = parse_tags(permitted_params[:tags])
        data.where('tags @> ?', tags.to_json)
      end
      # :nocov:

      # rubocop:disable Metrics/AbcSize
      # :nocov:
      def search(data)
        return data if permitted_params[:filter].blank?

        # Fail if search is not supported for the given model
        if !data.respond_to?(:search_for) || permitted_params[:filter].match(/\x00/)
          raise ActionController::UnpermittedParameters.new(filter: permitted_params[:filter])
        end

        data.search_for(permitted_params[:filter])
      end
      # :nocov:
      # rubocop:enable Metrics/AbcSize

      # :nocov:
      def sort(data)
        order_hash, extra_scopes = data.klass.build_order_by(permitted_params[:sort_by])

        extra_scopes.inject(data.order(order_hash)) do |result, scope|
          result.send(scope)
        end
      end
      # :nocov:
    end
  end
end
