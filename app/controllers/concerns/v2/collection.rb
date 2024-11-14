# frozen_string_literal: true

module V2
  # Generic methods to be used when calling fetch_collection on our models
  module Collection
    extend ActiveSupport::Concern

    include ::TagFiltering

    included do
      private

      # This is the method where you probably want to put a breakpoint to debug SQL
      def fetch_collection
        scope = filter_by_tags(search(expand_resource))
        count = count_collection(scope)
        # If the count of records equals zero, make sure that the parents are not accessible
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
        # Look up the `parents` array from the parent route and use it to scope down the parent
        # resource to make sure we throw a 404 if it is not accesible.
        scope = pundit_scope(join_parents(reflection.klass, parent_route_parents))
        scope.find(permitted_params[reflection.foreign_key])
      end

      # The parent route is usually 2 levels higher, as the current route contains the ID and the
      # resource name. In some cases when collection metadata like `os_versions` is requested, we
      # need to drop that extra level. The right level can be determined by checking the length
      # of the parents.
      def parent_route_parents
        [2, 3].filter_map do |level|
          route = parent_route(level)
          route[:parents] if route[:parents]&.count.to_i < permitted_params[:parents]&.count.to_i
        end.first
      end

      # Helper method to look up a parent route by removing the `level` amount of elements from
      # the current request path.
      def parent_route(level)
        path = request.path.split('/')[..-level].join('/')
        Rails.application.routes.recognize_path(path)
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
