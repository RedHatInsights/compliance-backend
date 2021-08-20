# frozen_string_literal: true

module Resolvers
  module Concerns
    # Module for Collection GraphQL fields, contains usual pagination options
    module Collection
      extend ActiveSupport::Concern

      include TagFiltering

      included do
        type ["Types::#{self::MODEL_CLASS}".safe_constantize], null: false
        argument :search, String, 'Search query', required: false
        argument :limit, Integer, 'Pagination limit', required: false
        argument :offset, Integer, 'Pagination offset', required: false
        argument :sort_by, [String], 'Sort results', required: false

        if TagFiltering.tags_supported?(self::MODEL_CLASS)
          argument :tags, [String], 'Filter by tags', required: false
        end
      end

      def resolve(**kwargs)
        filters = filter_list(**kwargs)
        base_scope = authorized_scope
        filters.reduce(base_scope) { |scope, filter| filter.call(scope) }
      end

      private

      def filter_list(
        search: nil, sort_by: nil, tags: nil, offset: nil, limit: nil
      )
        filters = []
        filters << search_filter(search: search) if search.present?

        filters << sort_filter(sort_by: sort_by) if sort_by.present?

        filters << tags_filter(tags: tags) if permit_tags?(tags)

        if offset.present? || limit.present?
          filters << pagination_filter(offset: offset, limit: limit)
        end

        filters
      end

      def pagination_filter(offset:, limit:)
        lambda do |scope|
          begin
            scope.paginate(page: offset, per_page: limit)
          rescue ScopedSearch::QueryNotSupported => e
            raise GraphQL::ExecutionError, e.message
          end
        end
      end

      def search_filter(search:)
        lambda do |scope|
          begin
            scope.search_for(search)
          rescue ScopedSearch::QueryNotSupported => e
            raise GraphQL::ExecutionError, e.message
          end
        end
      end

      def sort_filter(sort_by:)
        lambda do |scope|
          order_hash, extra_scopes = scope.klass.build_order_by(sort_by)

          extra_scopes.inject(scope.order(order_hash)) do |result, e_scope|
            result.send(e_scope)
          end
        end
      end

      def tags_filter(tags:)
        lambda do |scope|
          tags = parse_tags(tags)
          scope.where('tags @> ?', tags.to_json)
        end
      end

      def model_class
        self.class::MODEL_CLASS
      end

      def authorized_scope
        Pundit.policy_scope(context[:current_user], model_class)
      end

      def permit_tags?(tags)
        TagFiltering.tags_supported?(model_class) && tags.present?
      end
    end
  end
end
