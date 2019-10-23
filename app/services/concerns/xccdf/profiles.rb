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

        ::Profile.import!(@profiles.select(&:new_record?), ignore: true)
      end
      alias_method :save_profiles, :profiles

      private

      def account_profile_ref_ids
        @account.profiles.map(&:ref_id)
      end

      def clone_and_update(new_profiles)
        ::Profile.import!(new_profiles.map! do |profile|
          new_profile = @account.profiles.find_by(ref_id: profile.ref_id) ||
            profile.deep_clone
          new_profile.account ||= @account
          new_profile.hosts = new_profile.hosts | [@host]
          new_profile
        end, recursive: true)
        new_profiles
      end
    end
  end
end
