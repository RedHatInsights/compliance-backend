# frozen_string_literal: true

module V2
  # Concern to support lookups via other fields than IDs
  module Indexable
    extend ActiveSupport::Concern

    included do
      module ::ActiveRecord
        # Monkey-patching the `find` method to allow lookups other than by `id`
        class Relation
          def find(id)
            # Do not even try to look up by other keys if the ID is a valid UUID
            return super(id) if ::UUID.validate(id)

            # If the lookup does not return a result nor an exception, call `super` again to
            # ensure that an exception is raised.
            base_class.instance_variable_get(:@indexable).try(:call, self, id) || super(id)
          end
        end
      end
    end

    class_methods do
      private

      # This method defines a block for retrieving an entity using a unique identifier other
      # than `id`. The retrieval should ideally be with a `find_by!` method for proper error
      # handling done by the controllers.
      #
      # ```
      # indexable_by :os_minor_version do |scope, value|
      #   scope.find_by!(os_minor_version: value)
      # end
      #
      # # Or as a shorthand with a lambda converted to a block
      # indexable_by :os_minor_version, &->(scope, value) { scope.find_by!(os_minor_version: value) }
      # ```
      def indexable_by(_field, &block)
        @indexable = block
      end
    end
  end
end
