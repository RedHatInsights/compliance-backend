# frozen_string_literal: true

module V2
  # Abstract record class to be applied to all models
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include V2::Sortable
    include V2::Searchable
    include V2::Indexable

    ActiveRecord::Relation.include(V2::MergeWithAlias)

    AN = Arel::Nodes

    # Placeholder field for implicit searching that should always fail as we only want to support explicit search
    scoped_search on: :_____, ext_method: :unsupported_query

    def self.unsupported_query(_filter, _operator, value)
      raise ScopedSearch::QueryNotSupported, "'#{value}' is not a valid query string"
    end

    def self.count_by
      primary_key.to_sym
    end

    # Returns with a list of symbols describing one-to-one relationships
    def self.one_to_one
      reflections.each_with_object([]) do |(key, reflection), obj|
        obj << key.to_sym if reflection.has_one? || reflection.belongs_to?
      end
    end

    # Returns with a list of symbols describing one-to-many relationships
    def self.one_to_many
      reflections.each_with_object([]) do |(key, reflection), obj|
        obj << key.to_sym unless reflection.has_one? || reflection.belongs_to?
      end
    end

    # Does a self-join with the subquery using an arel fragment
    def self.arel_self_join(subquery)
      arel_join_fragment(select(primary_key).arel.join(subquery).on(subquery[primary_key].eq(arel_table[primary_key])))
    end

    # Creates an Arel-fragment from a self-joined subquery that can be passed as an argument
    # to the `ActiveRecord::Base.joins` method.
    def self.arel_join_fragment(scope)
      scope.ast.cores.first.source.right.first
    end

    # Splits up a version and converts it to an array of integers for better sorting
    def self.version_to_array(column)
      AN::NamedFunction.new(
        'CAST',
        [
          AN::NamedFunction.new(
            'string_to_array',
            [column, AN::Quoted.new('.')]
          ).as('int[]')
        ]
      )
    end

    # Looks up for an array of JSONs (using ANY/OR) in a column
    def self.arel_json_lookup(column, jsons)
      return AN::InfixOperation.new('=', Arel.sql('1'), Arel.sql('0')) if jsons.empty?

      AN::InfixOperation.new(
        '@>', column,
        AN::NamedFunction.new(
          'ANY', [
            AN::NamedFunction.new('CAST', [AN.build_quoted("{#{jsons.join(',')}}").as('jsonb[]')])
          ]
        )
      )
    end

    def self.arel_inotineqneq(operator, left, right)
      case operator
      when 'IN'
        AN::In.new(left, right)
      when 'NOT IN'
        AN::Not.new(AN::In.new(left, right))
      when '='
        left.eq(right.first)
      when '<>'
        left.not_eq(right.first)
      end
    end

    def self.bulk_assign(add, del)
      insert = delete = 0

      transaction do
        delete = del.delete_all
        insert = import(add, on_duplicate_key_ignore: true, validate: false)
      end

      [insert.ids.count, delete]
    end
  end
end
