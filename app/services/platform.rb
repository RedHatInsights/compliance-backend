# frozen_string_literal: true

require 'faraday'

# Methods related to connecting to other platform services
module Platform
  RETRY_OPTIONS = {
    max: 3,
    interval: 0.05,
    interval_randomness: 0.5,
    backoff_factor: 2,
    exceptions: [
      Faraday::ConnectionFailed, Faraday::TimeoutError, Errno::ETIMEDOUT,
      Timeout::Error, Error::TimeoutError
    ]
  }

  def self.connection
    faraday = Faraday.new do |f|
      f.response :raise_error
      f.request :retry, RETRY_OPTIONS
      f.adapter Faraday.default_adapter # this must be the last middleware
      f.ssl[:verify] = Rails.env.production?
    end
    faraday
  end
end
