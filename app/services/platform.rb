# frozen_string_literal: true

require 'faraday'

# Methods related to connecting to other platform services
module Platform
  def self.connection
    faraday = Faraday.new do |f|
      f.response :raise_error
      f.adapter Faraday.default_adapter # this must be the last middleware
      f.ssl[:verify] = Rails.env.production?
    end
    faraday
  end
end
