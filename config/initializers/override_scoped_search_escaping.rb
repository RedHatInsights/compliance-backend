# frozen_string_literal: true

# Monkeypatching the query parser in order to escape '%' and '_' from searches
# Code copied from https://github.com/wvanbergen/scoped_search/blob/master/lib/scoped_search/query_builder.rb
module ScopedSearch
  class QueryBuilder
    alias preprocess_parameters_old preprocess_parameters
    def preprocess_parameters(field, operator, value, &block)
      return preprocess_parameters_old(field, operator, value, &block) unless %i[like unlike].include?(operator)
      # Escaping the value part of the query
      value = ActiveRecord::Base.sanitize_sql_like(value)
      values = [value !~ /^\%|\*/ && value !~ /\%|\*$/ ? "%#{value}%" : value.tr_s('%*', '%')]
      values.each { |value| yield(:parameter, value) }
    end
  end
end
