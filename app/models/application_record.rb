# frozen_string_literal: true

# Abstract record class to be applied to all models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Sortable

  AN = Arel::Nodes

  scope :older_than, lambda { |datetime|
    where(arel_table[:created_at].lt(datetime))
  }

  def ==(other)
    return super if self.class.column_names.include? 'id'

    self.class.column_names.map do |col|
      send(col) == other.send(col)
    end.all?
  end

  def self.taggable?
    false
  end

  def self.count_by
    primary_key.to_sym
  end
end
