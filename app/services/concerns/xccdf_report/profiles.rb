# frozen_string_literal: true

module XCCDFReport
  # Methods related to saving profiles and finding which hosts
  # they belong to
  module Profiles
    extend ActiveSupport::Concern

    included do
      def save_profiles
        @oscap_parser.profiles.map do |ref_id, name|
          profile = Profile.find_or_initialize_by(name: name, ref_id: ref_id,
                                                  account_id: @account.id)
          unless profile.persisted?
            profile.update!(
              description: @oscap_parser.description
            )
          end

          profile
        end
      end

      def host_new_profiles
        save_profiles.select do |profile| # rubocop:disable Style/InverseMethods
          Rails.cache.delete("#{profile.id}/#{@host.id}/results")
          !profile.hosts.map(&:id).include? @host.id
        end
      end
    end
  end
end
