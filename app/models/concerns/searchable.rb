# frozen_string_literal: true

require 'exceptions'

# Concern to support searching among database records
module Searchable
  extend ActiveSupport::Concern

  OPERATOR_ALIASES = { neq: :ne }.freeze

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

    def validate_search_operators!(query)
      return if query.blank?

      ast = ScopedSearch::QueryLanguage::Compiler.parse(query)
      each_field_comparison(ast) do |field_name, operator|
        field = scoped_search.field_by_name(field_name)
        next if field.nil?

        declared = Array(field.operators).map { |op| OPERATOR_ALIASES.fetch(op, op) }
        next if declared.empty? || declared.include?(operator)

        raise ScopedSearch::QueryNotSupported, "Operator '#{operator}' is not supported for '#{field_name}'"
      end
    end

    private

    def each_field_comparison(node, &block)
      return unless node.is_a?(ScopedSearch::QueryLanguage::AST::OperatorNode)

      yield node.lhs.value, node.operator if field_comparison?(node)
      node.children.each { |child| each_field_comparison(child, &block) }
    end

    def field_comparison?(node)
      ScopedSearch::QueryLanguage::Parser::COMPARISON_OPERATORS.include?(node.operator) &&
        node.infix? && node.lhs.is_a?(ScopedSearch::QueryLanguage::AST::LeafNode)
    end
  end
end
