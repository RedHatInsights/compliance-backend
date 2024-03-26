# frozen_string_literal: true

require 'exceptions'

# Concern to support sorting returned database records
module Sortable
  extend ActiveSupport::Concern

  class_methods do
    def build_order_by(*fields)
      order = build_fields_order_by(fields)
      # Additional sorting if @default_sort is set
      order[:h][@default_sort] = :asc if @default_sort
      # Add ID for deterministic pagination
      order[:h][:id] = :asc unless order.include?(:id)

      order.values
    end

    private

    # Declares the field to be used for the basis of deterministic sorting
    # when retrieving records via the REST/GQL APIs.
    def default_sort(column)
      @default_sort = column
    end

    def sortable_by(column, statement = column, scope: nil)
      @sortable_by ||= {}
      @sortable_by[column] = {
        statement: statement,
        scope: scope
      }
    end

    def build_fields_order_by(fields)
      fields.compact.flatten.each_with_object(h: {}, s: []) do |field, obj|
        column, direction = field.underscore.split(':')
        assert_sortable_by!(column, direction)

        rule = @sortable_by[column.to_sym]
        obj[:h][rule[:statement]] = direction || 'asc'
        obj[:s] << rule[:scope] if rule[:scope]
      end
    end

    def assert_sortable_by!(column, direction)
      unless @sortable_by.key?(column&.to_sym)
        raise ::Exceptions::InvalidSortingColumn, column
      end

      return if ['asc', 'desc', nil].include?(direction)

      raise ::Exceptions::InvalidSortingDirection, direction
    end
  end
end
