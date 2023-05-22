# frozen_string_literal: true

require 'uri'
require 'json'

module Insights
  module Api
    module Common
      # Interact with the Insights Host Inventory. Usually HTTP calls are all that's needed.
      class HostInventory
        def initialize(account: nil, url: Settings.host_inventory_url,
                       b64_identity: nil)
          @url = "#{URI.parse(url)}#{Settings.path_prefix}/inventory/v1/hosts"
          @account = account
          @b64_identity = b64_identity || account&.b64_identity
        end

        def hosts
          get
        end

        private

        def get(path = '', params: {}, headers: { X_RH_IDENTITY: @b64_identity })
          JSON.parse(Platform.connection.get("#{@url}#{path}", params, headers).body)
        end
      end
    end
  end
end
