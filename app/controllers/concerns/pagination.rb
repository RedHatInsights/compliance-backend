# frozen_string_literal: true

# Default options and configuration for pagination
module Pagination
  extend ActiveSupport::Concern

  ParamType = ActionController::Parameters

  included do
    def pagination_limit
      permitted_params[:limit] || 10
    end

    def pagination_offset
      permitted_params[:offset] || 1
    end
  end
end
