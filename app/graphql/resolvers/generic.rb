# frozen_string_literal: true

module Resolvers
  # Base class for resolvers
  class Generic
    attr_reader :type

    def initialize(type)
      @type = type
    end

    def self.for(type)
      new(type)
    end

    def record
      return unless model_class

      base_class.include(Resolvers::Concerns::Record)
    end

    def collection
      return unless model_class

      base_class.include(Resolvers::Concerns::Collection)
    end

    private

    delegate :model_class, to: :type

    def base_class
      Class.new(Resolvers::BaseResolver).tap do |c|
        c.const_set('MODEL_CLASS', model_class)
      end
    end
  end
end
