# frozen_string_literal: true

require 'faraday'

module Insights
  module Api
    module Common
      # Methods related to connecting to other platform services
      module Platform
        BASIC_AUTH = [Settings.platform_basic_auth_username,
                      Settings.platform_basic_auth_password].freeze
        RETRY_OPTIONS = {
          max: 3,
          interval: 0.05,
          interval_randomness: 0.5,
          backoff_factor: 2,
          methods: %i[get],
          exceptions: [
            *Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS, Faraday::ConnectionFailed
          ]
        }.freeze

        def self.connection
          faraday = Faraday.new do |f|
            f.response :raise_error
            f.request :retry, RETRY_OPTIONS
            f.adapter Faraday.default_adapter # this must be the last middleware
            f.ssl[:verify] = Rails.env.production?
            f.basic_auth(*BASIC_AUTH) if BASIC_AUTH[0].present?
          end
          faraday
        end
      end
    end
  end
end
