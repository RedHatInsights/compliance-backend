# frozen_string_literal: true

# Abstract record class to be applied to all models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include Sortable

  scope :older_than, lambda { |datetime|
    where(arel_table[:created_at].lt(datetime))
  }

  def self.arel_find(collection, batch_size = 1000)
    base_arel = arel_table[column_names.first].eq('')
    collection.in_groups_of(batch_size, false).map do |batch|
      where(batch.inject(base_arel) do |rel, record|
        rel.or(yield(record))
      end)
    end.inject([], &:+)
  end

  def ==(other)
    return super if self.class.column_names.include? 'id'

    self.class.column_names.map do |col|
      send(col) == other.send(col)
    end.all?
  end
end
