# frozen_string_literal: true

require 'exceptions'

# Concern to support sorting returned database records
module Sorting
  extend ActiveSupport::Concern

  included do
    def build_order_by(model, *fields)
      order = build_fields_order_by(model, *fields)
      # add id for deterministic pagination
      order[:id] = :asc unless order.include?(:id)
      order
    end

    def build_fields_order_by(model, *fields)
      fields.compact.flatten.each_with_object({}) do |field, obj|
        column, direction = field.underscore.split(':')

        unless model::SORTABLE_BY.key?(column.to_sym)
          raise ::Exceptions::InvalidSortingColumn, column
        end

        unless ['asc', 'desc', nil].include?(direction)
          raise ::Exceptions::InvalidSortingDirection, direction
        end

        obj[model::SORTABLE_BY[column.to_sym]] = direction || 'asc'
      end
    end
  end
end
