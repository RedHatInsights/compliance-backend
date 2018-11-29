# frozen_string_literal: true

module XCCDFReport
  # Methods related to saving profiles and finding which hosts
  # they belong to
  module Profiles
    extend ActiveSupport::Concern

    included do
      def profiles
        result = {}
        @benchmark.profiles.each do |id, oscap_profile|
          result[id] = oscap_profile.title
        end
        result
      end

      def save_profiles
        created = []
        profiles.each do |ref_id, name|
          if (profile = Profile.find_by(name: name, ref_id: ref_id))
            created << profile
            next
          end
          created << Profile.create(name: name, ref_id: ref_id,
                                    description: report_description)
        end
        created
      end

      def new_profiles
        save_profiles.reject do |profile|
          profile.hosts.map(&:id).include? @host.id
        end
      end
    end
  end
end
