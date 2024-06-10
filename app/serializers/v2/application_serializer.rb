# frozen_string_literal: true

module V2
  # JSON serialization base class
  class ApplicationSerializer < Panko::Serializer
    attributes :id, :type

    def type
      object.model_name.element
    end

    class << self
      # Return the hash of depenencies to be selected from the database to be able to feed the serializer
      # with the required data. Merges the `@derived_attributes` with the declared model attributes.
      #
      # ```
      # {
      #   nil => derived_dependencies[nil] + attributes from serializer deduplicated,
      #   **derived_dependencies[except nil]
      # }
      # ```
      #
      def dependencies(parents, to_one)
        data = filter_from(@derived_attributes, (parents.to_a + to_one).uniq)
        data[nil] = (_descriptor.attributes.map(&:name).map(&:to_sym) + data[nil].to_a).compact
        data
      end

      # Match any declared `aggregate_field` against the available relationships, return with a hash of
      # aggregations in a `{ name => [field, alias] }` format.
      def aggregations(parents, to_many)
        filter_from(@aggregated_attributes, to_many - parents.to_a, true).each_with_object({}) do |(k, v), obj|
          obj[k] = v
        end
      end

      # Return the hash of dependencies for optional (weak) attributes in the same format as the `dependencies`
      # excluding the `nil` key as own fields are never optional.
      def weak_dependencies(parents)
        @weak_attributes&.values.to_a.each_with_object({}) do |(deps, fields), hsh|
          merge_dependencies(hsh, fields, false) if deps.all? { |dep| parents.try(:include?, dep) }
        end
      end

      # Panko's default way of skipping certain attributes is to construct a hash that contains a list of fields
      # that should be omitted. This method automatically receives a context and a scope argument, where we use
      # the context to pass the `params[:joined]` that are necessary to determine if the required tables are joined.
      #
      # https://panko.dev/docs/attributes#filters-for
      def filters_for(context, _scope)
        # Iterate through all the "method fields" and if any of them show up in the `@derived_attributes`, check if
        # the dependencies are not met. This builds a context-based list of attributes that should not be displayed.
        {
          except: reduce_method_fields([]) do |arr, field|
            arr.push(field) if to_be_excluded?(field, context)
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

      # This method allows the definition of loosely-coupled attributes that are derived from left-outer-joined
      # models. This means that if there is nothing to join with, their final value would be `nil`.
      def weak_attribute(name, *parents, **hsh)
        attributes name
        delegate name, to: :@object

        @weak_attributes ||= {}
        @weak_attributes[name] = [parents, hsh]
      end

      # This method allows the definition attributes that are aggregated from any left-outer-joined has_many
      # `association`. The attribute is forwarded to an `aggregate_#{name}` method in the model that should
      # exist as an attribute when calling the serializer. The result of the aggregation `function`  should
      # be aliased to this name when resolving the aggegation.
      def aggregated_attribute(name, association, function)
        target = "aggregate_#{name}"
        attributes name
        define_method(name) { @object.send(target.to_sym) }

        @aggregated_attributes ||= {}
        @aggregated_attributes[name] = { association => [function, target] }
      end

      protected

      # Derived attributes should be excluded if the required associations are not joined with the current scope,
      # i.e. there are no joined parents available. Aggregated attributes should be skipped when its dependencies
      # have been already joined to the current scope, i.e. there is an overlap with parents.
      # rubocop:disable Metrics/AbcSize
      def to_be_excluded?(field, context)
        @derived_attributes ||= {}
        @aggregated_attributes ||= {}
        @weak_attributes ||= {}

        [
          @derived_attributes.key?(field) && !meets_dependency?(@derived_attributes[field].keys, context[:joined]),
          @weak_attributes.key?(field) && !meets_dependency?(@weak_attributes[field].first, context[:joined]),
          @aggregated_attributes.key?(field) && meets_dependency?(@aggregated_attributes[field].keys, context[:joined])
        ].any?
      end
      # rubocop:enable Metrics/AbcSize

      # Reduces the "method fields" of the serializer to an array using a passed block
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
      # of the given association. Aggregated fields are keyed under the aggregated table with a similar
      # structure, but they contain an `[aggregation, alias]` pair instead.
      #
      # ```
      # {
      #   nil => [own_field1, own_field2, ...],
      #   another_table1 => [another_table_field1, another_table_field2, ...],
      #   another_table2 => [another_table_field1, another_table_field2, ...],
      #   another_table3 => [[aggregation, alias], [aggregation, alias], ...]
      # }
      # ```
      def filter_from(attributes, joined, aggregate = false)
        attributes ||= {}

        reduce_method_fields({}) do |obj, field|
          if attributes.key?(field) && meets_dependency?(attributes[field].keys, joined)
            merge_dependencies(obj, attributes[field], aggregate)
          end
        end
      end

      # Helper method for deep merging a hash of arrays, based on the `aggregate` parameter it can do
      # either a `+=` (standard) or a `<<` (aggregate) merge.
      def merge_dependencies(left, right, aggregate)
        right.each_with_object(left) do |(k, v), obj|
          obj[k] ||= []
          aggregate ? obj[k] << v : obj[k] += v
        end
      end
    end
  end
end
