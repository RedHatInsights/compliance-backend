# frozen_string_literal: true

# Generic methods to be used when calling scoped_search on our models
module Search
  extend ActiveSupport::Concern

  included do
    def scope_search
      result = policy_scope(resource)
      escape_references_search
      result = result.search_for(params[:search]) if params[:search].present?
      result.paginate(page: pagination_offset, per_page: pagination_limit)
    end

    def escape_references_search
      return unless params[:search]&.match(/reference=/)

      search_term = CGI.escape(params[:search].split('=')[1])
      params[:search] = "reference=#{search_term}"
    end
  end
end
