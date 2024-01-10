# frozen_string_literal: true

require 'exceptions'

module V2
  # Concern to support searching among database records
  module Searchable
    extend ActiveSupport::Concern

    class_methods do
      # This is a wrapper around scoped_search with some of our conventions around explicit-by-default
      # search and mandatory operator definitions. It also simplifies the usage of ext_method searches
      # by allowing them to be passed as blocks. The block's signature is the same as the ext_method's.
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
      def searchable_by(field, operators, **args, &)
        if block_given?
          args[:ext_method] = "__find_by_#{field}".to_sym
          define_singleton_method(args[:ext_method], &)
        end

        scoped_search on: field, operators: operators, only_explicit: true, **args
      end
    end
  end
end
