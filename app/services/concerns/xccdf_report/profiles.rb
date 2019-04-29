# frozen_string_literal: true

module XCCDFReport
  # Methods related to saving profiles and finding which hosts
  # they belong to
  module Profiles
    extend ActiveSupport::Concern

    included do
      def profiles
        return @profiles if @profiles.present?

        result = {}
        @report_xml.search('Profile').each do |profile|
          next unless test_result_node.attributes['id'].value.include?(
            profile.attributes['id'].value
          )

          result[profile.attributes['id'].value] = profile.search('title')
                                                          .children.text
        end
        @profiles = result
      end

      def save_profiles
        created = []
        # Only save profiles with an associated TestResult. Otherwise there
        # could be profiles saved w/o results.
        profiles.each do |ref_id, name|
          profile = Profile.find_or_initialize_by(name: name, ref_id: ref_id,
                                                  account_id: @account.id)
          profile.description = report_description
          profile.save
          created << profile
        end
        created
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
