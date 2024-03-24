# frozen_string_literal: true

module V2
  # Abstract record class to be applied to all models
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include V2::Sortable
    include V2::Searchable
    include V2::Indexable

    AN = Arel::Nodes

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

    # Creates an Arel-fragment from a self-joined subquery that can be passed as an argument
    # to the `ActiveRecord::Base.joins` method.
    # rubocop:disable Metrics/AbcSize
    def self.arel_join_fragment(subquery)
      select(primary_key).arel.join(subquery)
                         .on(subquery[primary_key].eq(arel_table[primary_key]))
                         .ast.cores.first.source.right.first
    end
    # rubocop:enable Metrics/AbcSize

    # Splits up a version and converts it to an array of integers for better sorting
    def self.version_to_array(column)
      Arel::Nodes::NamedFunction.new(
        'CAST',
        [
          Arel::Nodes::NamedFunction.new(
            'string_to_array',
            [column, Arel::Nodes::Quoted.new('.')]
          ).as('int[]')
        ]
      )
    end

    # Monkey-patching the list of RETURNING columns to always have the primary_key fields.
    # This issue has been introduced by Rails 7.1.3 and will be only fixed in 7.1.4 that
    # has not been released yet.
    #
    # FIXME: delete after Rails 7.1.4 is out
    def self._returning_columns_for_insert
      @_returning_columns_for_insert ||= begin
        auto_populated_columns = columns.filter_map do |c|
          c.name if connection.return_value_after_insert?(c)
        end

        auto_populated_columns.empty? ? Array(primary_key) : auto_populated_columns
      end
    end
  end
end
