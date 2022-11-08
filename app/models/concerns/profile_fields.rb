# frozen_string_literal: true

# Computed Fields of a Profile
module ProfileFields
  extend ActiveSupport::Concern

  included do
    def ssg_version
      benchmark.version
    end

    def policy_type
      (parent_profile || self).name
    end

    def supported_os_versions
      bm_versions.map do |v|
        SupportedSsg.by_ssg_version[v].select { |ssg| ssg.os_major_version == os_major_version }.map do |ssg|
          Gem::Version.new([ssg.os_major_version, ssg.os_minor_version].join('.'))
        end
      end.flatten.uniq.sort.reverse
    end

    def os_major_version
      # Try to reach for this in the cached attributes if possible
      (attributes['os_major_version'] || benchmark&.inferred_os_major_version).to_s
    end

    def os_version
      if os_minor_version.present?
        "#{os_major_version}.#{os_minor_version}"
      else
        os_major_version.to_s
      end
    end

    def canonical?
      parent_profile_id.blank?
    end

    private

    def bm_versions
      # Try to reach for this in the cached attributes if possible
      attributes['bm_versions'] || self.class.canonical.where(
        ref_id: ref_id,
        upstream: false
      ).joins(:benchmark).pluck('benchmarks.version')
    end
  end
end
