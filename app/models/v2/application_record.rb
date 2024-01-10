# frozen_string_literal: true

module V2
  # Abstract record class to be applied to all models
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include V2::Sortable
    include V2::Searchable

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
  end
end
