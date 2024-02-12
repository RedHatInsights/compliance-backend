# frozen_string_literal: true

module V2
  # JSON serialization base class
  class ApplicationSerializer < Panko::Serializer
    attributes :id, :type

    def type
      object.model_name.element
    end

    class << self
      # Return the hash of fields to be selected from the database to be able to feed the serializer
      # with the required data. Merges the `method_fields` with the declared model attributes.
      #
      # {
      #   nil => method_fields[nil] + attributes from serializer deduplicated,
      #   **method_fields[except nil]
      # }
      #
      def fields(parents, one_to_one)
        data = method_fields((parents.to_a + one_to_one).uniq)
        data[nil] = (_descriptor.attributes.map(&:name).map(&:to_sym) + data[nil].to_a).compact
        data
      end

      # Panko's default way of skipping certain attributes is to construct a hash that contains a list of fields
      # that should be omitted. This method automatically receives a context and a scope argument, where we use
      # the context to pass the `params[:joined]` that are necessary to determine if the required tables are joined.
      #
      # https://panko.dev/docs/attributes#filters-for
      def filters_for(context, _scope)
        @derived_attributes ||= {}

        # Iterate through all the `method_fields` and if any of them show up in the `@derived_attributes`, check if
        # the dependencies are not met. This builds a context-based list of attributes that should not be displayed.
        {
          except: reduce_method_fields([]) do |arr, field|
            if @derived_attributes.key?(field) && !meets_dependency?(@derived_attributes[field].keys, context[:joined])
              arr.push(field)
            end
          end
        }
      end

      private

      # This method allows the definition of derived attributes that are usually derived from other (joined)
      # models. The attribute is automatically delegated to the model where a method with the same name should
      # exist. Any dependencies from joined tables should be defined in the `association: [:column]` format.
      def derived_attribute(name, *arr, **hsh)
        attributes name
        delegate name, to: :@object

        @derived_attributes ||= {}
        @derived_attributes[name] = hsh.merge(nil => arr)
      end

      protected

      # Reduces the `method_fields` of the serializer to an array using a passed block
      def reduce_method_fields(initial, &block)
        _descriptor.method_fields.reduce(initial) do |arr, item|
          field = item.name.to_sym
          block.call(arr, field) || arr # Fallback if the block returns `nil`
        end
      end

      def meets_dependency?(dependencies, joined)
        joined ||= {}
        dependencies.all? { |key| key.nil? || joined.include?(key) }
      end

      # Returns a hash of DB fields that are further evaluated by model methods, own fields are grouped
      # under the `nil` key of the hash, fields from other joined associations are keyed under the name
      # of the given association.
      #
      # {
      #   nil => [own_field1, own_field2, ...],
      #   another_table1 => [another_table_field1, another_table_field2, ...],
      #   another_table2 => [another_table_field1, another_table_field2, ...]
      # }
      def method_fields(joined)
        @derived_attributes ||= {}

        reduce_method_fields({}) do |obj, field|
          if @derived_attributes.key?(field) && meets_dependency?(@derived_attributes[field].keys, joined)
            merge_dependencies(obj, @derived_attributes[field])
          end
        end
      end

      # Helper method for deep merging a hash of arrays
      def merge_dependencies(left, right)
        right.each_with_object(left) do |(k, v), obj|
          obj[k] ||= []
          obj[k] += v
        end
      end
    end
  end
end
