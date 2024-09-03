# frozen_string_literal: true

module V2
  # Generic methods to be used when calling fetch_collection on our models
  module Collection
    extend ActiveSupport::Concern

    include ::TagFiltering

    included do
      private

      def fetch_collection
        scope = filter_by_tags(search(expand_resource))
        count = count_collection(scope)
        # If the count of records equals zero, make sure that the parents exist.
        validate_parents! if count.zero? && permitted_params[:parents]&.any?

        sort(scope).limit(pagination_limit).offset(pagination_offset)
      end

      def count_collection(scope)
        # Count the whole collection using a single column and not the whole table. This column
        # by default is the primary key of the table, however, in certain cases using a different
        # indexed column might produce faster results without even accessing the table.
        # Pagination is disabled when counting collection so that all returned entities are counted.
        @count_collection ||= scope.except(:limit, :offset).reselect(resource.base_class.count_by).count
      end

      def validate_parents!
        current = permitted_params[:parents].last
        reflection = resource.reflect_on_association(current)
        scope = pundit_scope(join_parents(reflection.klass, parent_route_parents))
        scope.find(permitted_params[reflection.foreign_key])
      end

      # Look up the `parents` array from the parent route using a search in Rails' routing table
      def parent_route_parents
        Rails.application.routes.recognize_path(request.path.split('/')[..-2].join('/'))[:parents]
      end

      def filter_by_tags(data)
        unless TagFiltering.tags_supported?(resource) && permitted_params[:tags]&.any?
          return data
        end

        tags = parse_tags(permitted_params[:tags])
        data.where('tags @> ?', tags.to_json)
      end

      # rubocop:disable Metrics/AbcSize
      def search(data)
        return data if permitted_params[:filter].blank?

        # Fail if search is not supported for the given model
        if !data.respond_to?(:search_for) || permitted_params[:filter].match(/\x00/)
          raise ActionController::UnpermittedParameters.new(filter: permitted_params[:filter])
        end

        # Pass the parents to the current thread context as there is no other way to access
        # the parents from inside models. This is obviously an antipattern, but we are limited
        # by scoped_search here and I have not found any better option.
        Thread.current[:parents] = permitted_params[:parents]

        data.search_for(permitted_params[:filter])
      end
      # rubocop:enable Metrics/AbcSize

      def sort(data)
        order_hash = data.klass.build_order_by(permitted_params[:sort_by])
        data.order(order_hash)
      end
    end
  end
end
