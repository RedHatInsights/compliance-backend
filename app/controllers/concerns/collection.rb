# frozen_string_literal: true

# Generic methods to be used when calling resolve_collection on our models
module Collection
  extend ActiveSupport::Concern

  include Sorting

  included do
    def resolve_collection
      result = sort(search(policy_scope(resource)))
      result.paginate(page: pagination_offset, per_page: pagination_limit)
    end

    def search(data)
      return data if params[:search].blank?

      data.search_for(params[:search])
    end

    def sort(data)
      return data if params[:sort_by].blank?

      data.order(build_order_by(data.klass, params[:sort_by]))
    end
  end
end
