# frozen_string_literal: true

# Generic methods to be used when calling scoped_search on our models
module Search
  extend ActiveSupport::Concern

  included do
    def scope_search
      result = policy_scope(resource)
      result = result.search_for(params[:search]) if params[:search].present?
      result.paginate(page: pagination_offset, per_page: pagination_limit)
    end
  end
end
