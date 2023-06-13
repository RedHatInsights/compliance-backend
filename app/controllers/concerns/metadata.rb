# frozen_string_literal: true

# Sets up the metadata to be passed fo fast_jsonapi to be
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
    def metadata(opts = {})
      opts[:total] ||= count_collection

      {
        meta: {
          total: opts[:total],
          self.class::SEARCH => permitted_params[self.class::SEARCH],
          tags: tags,
          limit: pagination_limit,
          offset: pagination_offset,
          sort_by: permitted_params[:sort_by],
          relationships: relationships_enabled?
        }.compact,
        links: links(last_offset(opts[:total]))
      }
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    def links(last_offset)
      {
        first: meta_link(offset: 1),
        last: meta_link(offset: last_offset),
        previous: previous_link(last_offset),
        next: next_link(last_offset)
      }.compact
    end

    def path_prefix
      request.fullpath[%r{(/(\w+))+/compliance}].sub(%r{/compliance}, '')
    end

    def previous_link(last_offset)
      return unless pagination_offset > 1 && pagination_offset <= last_offset

      meta_link(offset: previous_offset)
    end

    def next_link(last_offset)
      return unless pagination_offset < last_offset

      meta_link(offset: next_offset(last_offset))
    end

    def previous_offset
      [(pagination_offset - 1), 1].max
    end

    def next_offset(last_offset)
      return last_offset if (pagination_offset + 1) >= last_offset

      pagination_offset + 1
    end

    def last_offset(total)
      (total / pagination_limit.to_f).ceil
    end

    private

    def count_collection
      # Count the whole collection using a single column and not the whole table. This column
      # by default is the primary key of the table, however, in certain cases using a different
      # indexed column might produce faster results without even accessing the table.
      resolve_collection.except(:select).select(resolve_collection.base_class.count_by).count
    end

    def base_link_url
      api_version = request.fullpath.delete_prefix("#{path_prefix}/#{Settings.app_name}")
      api_version.sub!(%r{/#{controller_name}.*}, '')
      "#{path_prefix}/#{Settings.app_name}#{api_version}/#{controller_name}"
    end

    def base_link_params
      {
        self.class::SEARCH => permitted_params[self.class::SEARCH],
        include: permitted_params[:include],
        limit: pagination_limit,
        tags: permitted_params[:tags],
        sort_by: permitted_params[:sort_by],
        relationships: relationships_enabled?
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
