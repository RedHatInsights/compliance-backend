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
            benchmark_id: @benchmark&.id
          )
        end

        ::Profile.import!(new_profiles, ignore: true)
      end
      alias_method :save_profiles, :profiles

      private

      def new_profiles
        @new_profiles ||= @profiles.select(&:new_record?)
      end

      def old_profiles
        @old_profiles ||= ::Profile.where(
          ref_id: @op_profiles.map(&:id), benchmark: @benchmark&.id
        ).index_by(&:ref_id)
      end
    end
  end
end
