# frozen_string_literal: true

require 'uri'
require 'json'

module Insights
  module Api
    module Common
      # Client for the Insights Host Inventory HTTP API.
      class HostInventory
        PER_PAGE = 100
        # Safety valve against runaway pagination (e.g. a misbehaving HBI that
        # keeps returning full pages). MAX_PAGES * PER_PAGE = 10k hosts; reaching
        # it logs a warning rather than truncating silently.
        MAX_PAGES = 100

        def initialize(account: nil, url: Settings.endpoints.host_inventory.url,
                       b64_identity: nil)
          @url = "#{URI.parse(url)}#{Settings.path_prefix}/inventory/v1/hosts"
          @account = account
          @b64_identity = b64_identity || account&.b64_identity
        end

        def hosts
          get
        end

        def host_ids_by_tags(tags)
          each_host_page(tags).flat_map { |page| page.map { |h| h['id'] } }
        end

        private

        # Yields each page of HBI results until a short (final) page is reached.
        # The short page is yielded before stopping, so every response is
        # processed. Capped at MAX_PAGES; hitting the cap logs a warning.
        def each_host_page(tags)
          return enum_for(:each_host_page, tags) unless block_given?

          (1..MAX_PAGES).each do |page|
            results = fetch_host_page(tags, page)
            yield results
            break if results.size < PER_PAGE

            warn_pagination_cap if page == MAX_PAGES
          end
        end

        def warn_pagination_cap
          Rails.logger.warn(
            "[HostInventory] host_ids_by_tags hit MAX_PAGES (#{MAX_PAGES}); results truncated"
          )
        end

        def fetch_host_page(tags, page)
          query = Faraday::FlatParamsEncoder.encode(tags: Array(tags), per_page: PER_PAGE, page: page)
          get("?#{query}").dig('results') || []
        end

        def get(path = '', params: {}, headers: { 'X-RH-IDENTITY': @b64_identity })
          JSON.parse(Platform.connection.get("#{@url}#{path}", params, headers).body)
        end
      end
    end
  end
end
