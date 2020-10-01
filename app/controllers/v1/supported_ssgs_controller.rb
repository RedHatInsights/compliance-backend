# frozen_string_literal: true

require 'yaml'

module V1
  # API for Supported SSGs mapped to RHEL minor versions
  class SupportedSsgsController < ApplicationController
    def index
      render_json supported_ssgs
    end

    private

    def metadata(opts = {})
      opts[:total] ||= supported_ssgs.count
      {
        meta: {
          total: opts[:total],
          revision: resource.revision
        }
      }
    end

    def resource
      SupportedSsg
    end

    def serializer
      SupportedSsgSerializer
    end

    def supported_ssgs
      @supported_ssgs ||= resource.all
    end
  end
end
