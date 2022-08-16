# frozen_string_literal: true

# Monkeypatching the query parser in order to escape '%' and '_' from searches
# Code copied from https://github.com/wvanbergen/scoped_search/blob/master/lib/scoped_search/query_builder.rb
module ScopedSearch
  class QueryBuilder
    alias preprocess_parameters_old preprocess_parameters

    INVERTED_OPERATORS = SQL_OPERATORS.invert.merge('ILIKE' => :like, 'NOT ILIKE' => :unlike).freeze

    # scoped_search gem does not preprocess values before passing to ext_method but sometimes it is necessary
    # This method can be called from a scoped search ext_method to preprocess parameters
    def self.preprocess_parameters(definition, field, operator, value)
      # Passing empty block because nothing needs to happen on yield in preprocess_parameters
      # The correct yield is invoked in to_ext_method_sql so all notification values are updated correctly
      # See https://github.com/wvanbergen/scoped_search/blob/master/lib/scoped_search/query_builder.rb
      qb = ScopedSearch::QueryBuilder.new(definition, '', definition.profile)
      qb.preprocess_parameters(field, INVERTED_OPERATORS[operator], value) { |_| }
    end

    def preprocess_parameters(field, operator, value, &block)
      return preprocess_parameters_old(field, operator, value, &block) unless %i[like unlike].include?(operator)
      # Escaping the value part of the query
      value = ActiveRecord::Base.sanitize_sql_like(value)
      values = [value !~ /^\%|\*/ && value !~ /\%|\*$/ ? "%#{value}%" : value.tr_s('%*', '%')]
      values.each { |value| yield(:parameter, value) }
    end
  end
end
