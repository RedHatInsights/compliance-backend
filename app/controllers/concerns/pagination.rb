# frozen_string_literal: true

# Default options and configuration for pagination
module Pagination
  extend ActiveSupport::Concern
  included do
    def pagination_limit
      params[:limit].present? ? params[:limit].to_i : 10
    end

    def pagination_offset
      params[:offset].present? ? params[:offset].to_i : 1
    end
  end
end
