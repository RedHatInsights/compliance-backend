# frozen_string_literal: true

module Xccdf
  # Methods related to saving the profile OS minor version support matrix
  module ProfileOsMinorVersions
    extend ActiveSupport::Concern

    included do
      def save_profile_os_minor_versions
        ::ProfileOsMinorVersion.transaction do
          # Delete all existing mappings for the given benchmark
          old_profile_os_minor_versions.delete_all
          # Import the new mappings
          ::ProfileOsMinorVersion.import!(new_profile_os_minor_versions)
        end
      end

      private

      def new_profile_os_minor_versions
        @profiles.flat_map do |profile|
          os_minor_versions.map do |os_minor_version|
            ::ProfileOsMinorVersion.new(profile: profile, os_minor_version: os_minor_version)
          end
        end
      end

      def old_profile_os_minor_versions
        @old_profile_os_minor_versions ||= ::ProfileOsMinorVersion.where(profile: @profiles.map(&:id))
      end

      def os_minor_versions
        SupportedSsg.by_ssg_version(true)[@benchmark.version]
                    .select { |ssg| ssg.os_major_version == @benchmark.os_major_version }
                    .map(&:os_minor_version)
      end
    end
  end
end
