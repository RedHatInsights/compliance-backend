# frozen_string_literal: true

require 'yaml'

# rubocop:disable Metrics/BlockLength
SupportedSsg = Struct.new(:id, :package, :version, :upstream_version, :profiles,
                          :os_major_version, :os_minor_version,
                          keyword_init: true) do
  self::SUPPORTED_FILE = Rails.root.join('config/supported_ssg.yaml')
  OS_NAME = 'RHEL'
  self::OS_NAME = OS_NAME

  def ref_id
    'xccdf_org.ssgproject' \
    ".content_benchmark_#{OS_NAME}-#{os_major_version}"
  end

  class << self
    def supported?(ssg_version:, os_major_version:, os_minor_version:)
      ssg_version == ssg_for_os(os_major_version, os_minor_version)
    end

    def ssg_for_os(os_major_version, os_minor_version)
      raw_supported.dig(
        'supported',
        "#{self::OS_NAME}-#{os_major_version}.#{os_minor_version}",
        'version'
      )
    end

    def all
      raw_supported['supported'].map do |rhel, values|
        major, minor = os_version(rhel)

        new(
          id: rhel,
          os_major_version: major,
          os_minor_version: minor,
          **map_attributes(values)
        )
      end
    end

    def revision
      raw_supported['revision']
    end

    # Collection of supported SSGs that have ZIP available upstream
    def available_upstream
      all.reject do |ssg|
        ssg.upstream_version&.upcase == 'N/A'
      end
    end

    def latest_per_os_major
      all.group_by(&:os_major_version).values.map do |ssgs|
        ssgs.max_by { |ssg| ssg.os_minor_version.to_i }
      end
    end

    private

    def map_attributes(values)
      attrs = values.slice(*members.map(&:to_s))
      attrs.symbolize_keys
    end

    def os_version(rhel)
      rhel.scan(/(\d+)\.(\d+)$/)[0]
    end

    def raw_supported
      # cached for the whole runtime
      @raw_supported ||= YAML.load_file(self::SUPPORTED_FILE)
    end
  end
end
# rubocop:enable Metrics/BlockLength
