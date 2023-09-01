# frozen_string_literal: true

module V2
  # Default options and configuration for pagination
  module Pagination
    extend ActiveSupport::Concern

    ParamType = ActionController::Parameters

    included do
      def pagination_limit
        permitted_params[:limit] || 10
      end

      def pagination_offset
        permitted_params[:offset] || 0
      end
    end
  end
end
