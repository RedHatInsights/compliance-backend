# frozen_string_literal: true

# Generic methods to be used when calling scoped_search on our models
module Search
  extend ActiveSupport::Concern

  included do
    def scope_search(pagination = true)
      return policy_scope(resource) unless params[:search]

      scope = policy_scope(resource).search_for(params[:search])
      return scope unless pagination

      scope.paginate(page: pagination_offset, per_page: pagination_limit)
    end
  end
end
