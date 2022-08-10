# frozen_string_literal: true

require 'yaml'

# rubocop:disable Metrics/BlockLength
SupportedSsg = Struct.new(:id, :package, :version, :profiles,
                          :os_major_version, :os_minor_version,
                          keyword_init: true) do
  OS_NAME = 'RHEL'
  self::OS_NAME = OS_NAME

  def ref_id
    'xccdf_org.ssgproject' \
    ".content_benchmark_#{OS_NAME}-#{os_major_version}"
  end

  def comparable_version
    Gem::Version.new(version)
  end

  def version_with_revision
    Gem::Version.new(
      package.sub(/^scap-security-guide-(.*)\.el.*$/, '\1')
    )
  end

  class << self
    def supported?(ssg_version:, os_major_version:, os_minor_version:)
      ssg_versions_for_os(os_major_version, os_minor_version)
        .include?(ssg_version)
    end

    def for_os(os_major_version, os_minor_version)
      os_major_version = os_major_version.to_s
      os_minor_version = os_minor_version.to_s

      all.select do |ssg|
        ssg.os_major_version == os_major_version &&
          ssg.os_minor_version == os_minor_version
      end
    end

    def ssg_versions_for_os(os_major_version, os_minor_version)
      for_os(os_major_version, os_minor_version).map(&:version)
    end

    def versions
      all.map(&:version).uniq
    end

    def all
      raw_supported['supported'].flat_map do |rhel, packages|
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

    def revision
      raw_supported['revision']
    end

    # Multilevel map of latest supported SSG for OS major and minor version
    def latest_map
      cache(:map) { build_latest_map }
    end

    def by_os_major
      all.group_by(&:os_major_version)
    end

    def by_ssg_version
      cache(:'by-ssg') { all.group_by(&:version) }
    end

    def clear
      Rails.cache.delete_matched('SupportedSsg/datastreams/*')
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

    def raw_supported
      SsgConfigDownloader.update_ssg_ds unless SsgConfigDownloader.exists?
      cache(:raw) { YAML.safe_load(SsgConfigDownloader.ssg_ds) }
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

    def cache(key, &block)
      Rails.cache.fetch("SupportedSsg/datastreams/#{key}", expires_on: 1.day, &block)
    end
  end
end
# rubocop:enable Metrics/BlockLength
