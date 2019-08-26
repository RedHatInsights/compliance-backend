# frozen_string_literal: true

module Types
  # Definition of the BaseObject type in GraphQL
  class BaseObject < GraphQL::Schema::Object
    protected

    def lookahead_includes(lookahead, object, selects_includes)
      selects_includes.each do |selects, includes|
        object = object.includes(includes) if lookahead.selects?(selects)
      end

      object
    end
  end
end
