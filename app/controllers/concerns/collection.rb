# frozen_string_literal: true

# Generic methods to be used when calling resolve_collection on our models
module Collection
  extend ActiveSupport::Concern

  include Sorting
  include TagFiltering

  included do
    def resolve_collection
      result = filter_by_tags(sort(search(policy_scope(resource))))
      result.paginate(page: pagination_offset, per_page: pagination_limit)
    end

    def filter_by_tags(data)
      unless TagFiltering.tags_supported?(resource) && params[:tags]&.any?
        return data
      end

      tags = parse_tags(params[:tags])
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
  end
end
