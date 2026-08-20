# frozen_string_literal: true

require 'yaml'

# rubocop:disable Metrics/BlockLength
SupportedSsg = Struct.new(:id, :package, :version, :profiles,
                          :os_major_version, :os_minor_version,
                          keyword_init: true) do
  OS_NAME = 'RHEL'
  self::OS_NAME = OS_NAME

  CACHE_PREFIX = 'SupportedSsg/datastreams'

  def ref_id
    'xccdf_org.ssgproject' \
    ".content_benchmark_#{OS_NAME}-#{os_major_version}"
  end

  def comparable_version
    Gem::Version.new(version)
  end

  def version_with_revision
    Gem::Version.new(
      package.sub(/^scap-security-guide-/, '').sub(/\.el.*$/, '')
    )
  end

  class << self
    def supported?(ssg_version:, os_major_version:, os_minor_version:)
      ssg_versions_for_os(os_major_version, os_minor_version)
        .include?(ssg_version)
    end

    def for_os(os_major_version, os_minor_version)
      for_major = by_os_major[os_major_version.to_s] || []
      exact = for_major.select { |ssg| ssg.os_minor_version == os_minor_version.to_s }

      # Fall back to the minor-0 datastream when no exact minor is shipped (upstream/IoP content).
      exact.any? ? exact : for_major.select { |ssg| ssg.os_minor_version == '0' }
    end

    def resolve_minor(os_major_version, os_minor_version)
      os_major_version = os_major_version.to_s
      os_minor_version = os_minor_version.to_s

      exact = all.any? do |ssg|
        ssg.os_major_version == os_major_version &&
          ssg.os_minor_version == os_minor_version
      end

      (exact ? os_minor_version : '0').to_i
    end

    # True when a major ships a single minor-0 datastream that acts as a wildcard for every minor
    # (upstream/IoP content). Hosted content ships per-minor datastreams, so this is false and only
    # the minors actually present are supported.
    def minor_agnostic?(os_major_version)
      minors = by_os_major[os_major_version.to_s]&.map(&:os_minor_version)&.uniq
      minors == ['0']
    end

    def ssg_versions_for_os(os_major_version, os_minor_version)
      for_os(os_major_version, os_minor_version).map(&:version).uniq
    end

    def versions
      all.map(&:version).uniq
    end

    def all(force = false)
      raw_supported(force)['supported'].flat_map do |rhel, packages|
        major, minor = os_version(rhel)

        packages.map do |raw_attrs|
          new(
            os_major_version: major,
            os_minor_version: minor,
            **map_attributes(rhel, raw_attrs)
          )
        end
      end
    end

    def revision(force = false)
      @revision = nil if force

      @revision ||= raw_supported(force)['revision']
    end

    # Multilevel map of latest supported SSG for OS major and minor version
    def latest_map
      cache_wrapper(:map) { build_latest_map }
    end

    def by_os_major
      all.group_by(&:os_major_version)
    end

    def by_ssg_version(force = false)
      cache_wrapper(:'by-ssg', force) { all(true).group_by(&:version) }
    end

    def clear
      Rails.cache.delete_matched("#{CACHE_PREFIX}/*")
    end

    private

    def map_attributes(rhel, raw_attrs)
      attrs = raw_attrs.slice(*members.map(&:to_s))
      attrs[:id] = "#{rhel}:#{raw_attrs['package']}"
      attrs.symbolize_keys
    end

    def os_version(rhel)
      rhel.scan(/(\d+)\.(\d+)$/)[0]
    end

    def raw_supported(force = false)
      cache_wrapper(:raw, force) do
        SsgConfigDownloader.update_ssg_ds
        YAML.safe_load(SsgConfigDownloader.ssg_ds)
      end
    end

    def build_latest_map
      all.group_by(&:os_major_version).transform_values do |major_ssgs|
        major_ssgs
          .group_by(&:os_minor_version)
          .transform_values do |minor_ssgs|
            minor_ssgs.max_by(&:comparable_version)
          end.freeze
      end.freeze
    end

    # The optional force parameter is responsible for bypassing the cache when importing
    def cache_wrapper(key, force = false, &block)
      force ? block.call : Rails.cache.fetch("#{CACHE_PREFIX}/#{key}", expires_on: 1.day, &block)
    end
  end
end
# rubocop:enable Metrics/BlockLength
