# frozen_string_literal: true

module Xccdf
  # Methods related to saving profiles and finding which hosts they belong to
  module Profiles
    extend ActiveSupport::Concern

    included do
      def profiles
        @profiles ||= @op_profiles.map do |op_profile|
          ::Profile.from_openscap_parser(
            op_profile,
            existing: old_profiles[op_profile.id],
            benchmark_id: @benchmark&.id,
            value_overrides: value_overrides(op_profile)
          )
        end
      end

      def save_profiles
        # Import the new records first with validation
        ::Profile.import!(new_profiles, ignore: true)

        # Update the fields on existing profiles, validation is not necessary
        ::Profile.import(old_profiles.values,
                         on_duplicate_key_update: {
                           conflict_target: %i[ref_id benchmark_id],
                           index_predicate: 'parent_profile_id IS NULL',
                           columns: %i[value_overrides]
                         }, validate: false)
      end

      private

      def new_profiles
        @new_profiles ||= profiles.select(&:new_record?)
      end

      def old_profiles
        @old_profiles ||= ::Profile.where(
          ref_id: @op_profiles.map(&:id), benchmark: @benchmark&.id
        ).index_by(&:ref_id)
      end

      def value_overrides(op_profile)
        op_profile.refined_values.each_with_object({}) do |(value_id, selector), value_map|
          value_definition = value_definition_for(ref_id: value_id)
          value_map[value_definition.id] = value_definition.op_source.value(selector)
        end
      end
    end
  end
end
