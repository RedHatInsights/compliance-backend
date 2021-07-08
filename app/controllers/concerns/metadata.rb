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
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def metadata(opts = {})
      opts[:total] ||= resolve_collection.count

      {
        meta: {
          total: opts[:total],
          search: params[:search],
          tags: tags_supported? ? params.fetch(:tags, []) : nil,
          limit: pagination_limit,
          offset: pagination_offset
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
      (pagination_offset - 1) <= 1 ? 1 : (pagination_offset - 1)
    end

    def next_offset(last_offset)
      return last_offset if (pagination_offset + 1) >= last_offset

      pagination_offset + 1
    end

    def last_offset(total)
      (total / pagination_limit.to_f).ceil
    end

    private

    def base_link_url
      "#{path_prefix}/#{Settings.app_name}/#{controller_name}"
    end

    def base_link_params
      {
        search: params[:search],
        include: params[:include],
        limit: pagination_limit
      }
    end

    def meta_link(other_params = {})
      link_params = base_link_params.merge(other_params).compact
      "#{base_link_url}?#{link_params.to_query}"
    end
  end
end
