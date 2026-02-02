# frozen_string_literal: true

module Xccdf
  # Methods related to saving value definitions
  module ValueDefinitions
    extend ActiveSupport::Concern

    included do
      def value_definitions
        @value_definitions ||= @op_value_definitions.map do |op_value_definition|
          ::V2::ValueDefinition.from_parser(
            op_value_definition,
            existing: old_value_definitions[op_value_definition.id],
            security_guide_id: security_guide&.id
          )
        end
      end

      def save_value_definitions
        # Import the new records first with validation
        ::V2::ValueDefinition.import!(new_value_definitions, ignore: true)

        # Update the fields on existing value_definitions, validation is not necessary
        ::V2::ValueDefinition.import(old_value_definitions.values,
                                     on_duplicate_key_update: {
                                       conflict_target: %i[ref_id security_guide_id],
                                       columns: %i[description default_value]
                                     }, validate: false)
      end

      private

      def new_value_definitions
        @new_value_definitions ||= value_definitions.select(&:new_record?)
      end

      def old_value_definitions
        @old_value_definitions ||= ::V2::ValueDefinition.where(
          ref_id: @op_value_definitions.map(&:id), security_guide_id: security_guide&.id
        ).index_by(&:ref_id)
      end

      def value_definition_for(ref_id:)
        @cached_value_definitions ||= value_definitions.index_by(&:ref_id)
        @cached_value_definitions[ref_id]
      end
    end
  end
end
