# frozen_string_literal: true

# Default options and configuration for pagination
module Pagination
  extend ActiveSupport::Concern

  ParamType = ActionController::Parameters

  included do
    def pagination_limit
      params.permit(limit: ParamType.integer & ParamType.gt(0))[:limit] || 10
    end

    def pagination_offset
      params.permit(offset: ParamType.integer & ParamType.gt(0))[:offset] || 1
    end
  end
end
