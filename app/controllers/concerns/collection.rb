# frozen_string_literal: true

# Generic methods to be used when calling resolve_collection on our models
module Collection
  extend ActiveSupport::Concern

  include Sorting

  included do
    def resolve_collection
      result = filter_by_tags(sort(search(policy_scope(resource))))
      result.paginate(page: pagination_offset, per_page: pagination_limit)
    end

    def filter_by_tags(data)
      tags = params[:tags]
      return data unless tags? && tags&.any?

      data.where('tags @> ?', tags.to_json)
    end

    def search(data)
      return data if params[:search].blank?

      data.search_for(params[:search])
    end

    def sort(data)
      return data if params[:sort_by].blank?

      data.order(build_order_by(data.klass, params[:sort_by]))
    end

    private

    def tags?
      resource.column_names.include?('tags')
    end
  end
end
