# frozen_string_literal: true

module Exceptions
  # Exception for wrong sorting directions in ActiveRecord
  class InvalidSortingDirection < ArgumentError
    def initialize(direction)
      super("Sorting direction #{direction} is invalid. Valid directions "\
            "are 'asc' or 'desc'.")
    end
  end

  # Exception for trying to sort based an unsortable or nonexisting column
  class InvalidSortingColumn < StandardError
    def initialize(column)
      super("Result cannot be sorted by the '#{column}' column.")
    end
  end

  # Exception for unparsable fields in tag(s)
  class InvalidTagEncoding < StandardError
    def initialize
      super('Invalid encoding of tag(s)')
    end
  end
end
