# frozen_string_literal: true

module V2
  # Abstract record class to be applied to all models
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include V2::Sortable
    include V2::Searchable
    include V2::Indexable

    AN = Arel::Nodes

    def self.taggable?
      false
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

    # Creates an Arel-fragment from a self-joined subquery that can be passed as an argument
    # to the `ActiveRecord::Base.joins` method.
    # rubocop:disable Metrics/AbcSize
    def self.arel_join_fragment(subquery)
      select(primary_key).arel.join(subquery)
                         .on(subquery[primary_key].eq(arel_table[primary_key]))
                         .ast.cores.first.source.right.first
    end
    # rubocop:enable Metrics/AbcSize
  end
end
