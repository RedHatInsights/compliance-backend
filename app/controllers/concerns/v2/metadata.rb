# frozen_string_literal: true

module V2
  # Sets up the metadata to be passed to fast_jsonapi to be
  # added to our API responses
  module Metadata
    extend ActiveSupport::Concern

    included do
      before_action :set_headers

      def set_headers
        response.headers['Content-Type'] = 'application/vnd.api+json'
      end

      # This is part of a JSON schema, no need for strict metrics
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def metadata(model)
        total ||= count_collection(model)

        {
          meta: {
            total: total,
            filter: permitted_params[:filter],
            tags: tags,
            limit: pagination_limit,
            offset: pagination_offset,
            sort_by: permitted_params[:sort_by]
          }.compact,
          links: links(last_offset(total))
        }
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def links(last_offset)
        {
          first: meta_link(offset: 0),
          last: meta_link(offset: last_offset),
          previous: previous_link,
          next: next_link(offset: last_offset)
        }.compact
      end

      def path_prefix
        request.fullpath[%r{(/(\w+))+/compliance}].sub(%r{/compliance}, '')
      end

      def previous_link
        return unless pagination_offset.positive?

        meta_link(offset: previous_offset)
      end

      def next_link(offset:)
        return unless pagination_offset < offset

        meta_link(offset: next_offset(offset))
      end

      def previous_offset
        [(pagination_offset - pagination_limit), 0].max
      end

      def next_offset(last_offset)
        return last_offset if (pagination_offset + pagination_limit) >= last_offset

        pagination_offset + pagination_limit
      end

      def last_offset(total)
        return 0 if total.zero?

        ((last_page(total) - 1) * pagination_limit) + pagination_offset
      end

      def last_page(total)
        ((total - pagination_offset) / pagination_limit.to_f).ceil
      end

      private

      def base_link_url
        api_version = request.fullpath.delete_prefix("#{path_prefix}/#{Settings.app_name}")
        api_version.sub!(%r{/#{controller_name}.*}, '')
        "#{path_prefix}/#{Settings.app_name}#{api_version}/#{controller_name}"
      end

      def base_link_params
        {
          filter: permitted_params[:filter],
          include: permitted_params[:include],
          limit: pagination_limit,
          tags: permitted_params[:tags],
          sort_by: permitted_params[:sort_by]
        }
      end

      def meta_link(other_params = {})
        link_params = base_link_params.merge(other_params).compact
        # As the tags aren't a "real" array, unfortunately, we have to do these
        # kind of jugglings to build the URL properly
        # rubocop:disable Style/RedundantRegexpArgument
        [
          base_link_url,
          link_params.to_query
                     .sub(/^tag%5B%5D\=/, 'tags=')
                     .gsub(/\&tags%5B%5D\=/, '&tags=')
        ].join('?')
        # rubocop:enable Style/RedundantRegexpArgument
      end

      def tags
        TagFiltering.tags_supported?(resource) ? params.fetch(:tags, []) : nil
      end
    end
  end
end
