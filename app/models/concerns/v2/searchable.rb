# frozen_string_literal: true

require 'exceptions'

module V2
  # Concern to support searching among database records
  module Searchable
    extend ActiveSupport::Concern

    # The validator is used to ensure that some fields are not available for searching under certain
    # parent hierarchy combinations. It is expected that the controller passes the parents to the
    # current thread context before calling seach_for.
    module ParentValidator
      def self.new(except, only)
        lambda do |_|
          parents = Thread.current[:parents].to_a

          !(only.any? && !parents.intersect?(only)) && !(except.any? && parents.intersect?(except))
        end
      end
    end

    class_methods do
      # This is a wrapper around scoped_search with some of our conventions around explicit-by-default
      # search and mandatory operator definitions. It also simplifies the usage of ext_method searches
      # by allowing them to be passed as blocks. The block's signature is the same as the ext_method's.
      # Additionally, the `except_parents` and `only_parents` arrays can be used for search restriction
      # to specific parent hierarchies.
      #
      # For more info see: https://github.com/wvanbergen/scoped_search/wiki/search-definition
      #
      # Examples:
      # ```ruby
      # searchable_by username, operators: %i[eq ne like unlike]
      #
      # searchable_by full_name, operators: %i[eq] do |_key, _op, val|
      #   { condition: 'first_name = ? OR last_name = ?', parameters: [val] }
      # end
      # ```
      def searchable_by(field, operators, except_parents: [], only_parents: [], **args, &)
        if block_given?
          args[:ext_method] = "__find_by_#{field}".to_sym
          define_singleton_method(args[:ext_method], &)
        end

        validator = ParentValidator.new(except_parents, only_parents)
        scoped_search on: field, operators: operators, validator: validator, only_explicit: true, **args
      end
    end
  end
end
