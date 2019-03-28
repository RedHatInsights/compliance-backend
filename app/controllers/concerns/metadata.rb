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

    def metadata(opts)
      options = {}
      options[:meta] = { total: opts[:total], search: params[:search] }
      options[:links] = links(opts[:total])
      options
    end

    def links(count)
      base_url = "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}"\
        "/#{resource.model_name.route_key}"
      last_offset = count / pagination_limit
      {
        first: "#{base_url}?limit=#{pagination_limit}&offset=1",
        last: "#{base_url}?limit=#{pagination_limit}&offset=#{last_offset}",
        previous: previous_link(base_url),
        next: next_link(base_url, last_offset)
      }
    end

    def previous_link(base_url)
      "#{base_url}?limit=#{pagination_limit}&offset=#{previous_offset}"
    end

    def next_link(base_url, last_offset)
      "#{base_url}?limit=#{pagination_limit}&offset=#{next_offset(last_offset)}"
    end

    def previous_offset
      (pagination_offset - 1) <= 1 ? 1 : (pagination_offset - 1)
    end

    def next_offset(last_offset)
      return last_offset if (pagination_offset + 1) >= last_offset

      pagination_offset + 1
    end
  end
end
