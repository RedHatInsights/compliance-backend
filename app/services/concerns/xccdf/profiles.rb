# frozen_string_literal: true

module Xccdf
  # Methods related to saving profiles and finding which hosts they belong to
  module Profiles
    extend ActiveSupport::Concern

    included do
      def profiles
        @profiles ||= @op_profiles.map do |op_profile|
          ::Profile.from_openscap_parser(op_profile,
                                         benchmark_id: @benchmark&.id)
        end

        ::Profile.import!(new_profiles, ignore: true)
      end
      alias_method :save_profiles, :profiles

      private

      def split_profiles
        @split_profiles ||= @profiles.partition(&:new_record?)
      end

      def old_profiles
        split_profiles.last
      end

      def new_profiles
        split_profiles.first
      end
    end
  end
end
