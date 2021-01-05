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

    def past_ref_ids(os_major_version:, ref_id:, ssg_version:)
      ref_id.gsub!(Profile::REF_ID_PREFIX, '')

      ssg = all.each_with_index.find do |ssg, i|
        ssg.os_major_version == os_major_version &&
          ssg.version == ssg_version
      end
    end

    def equivalent_ref_ids(ref_id:, os_major_version:, ssg_version:)
      ref_id.gsub!(Profile::REF_ID_PREFIX, '')
      equivalent_ref_ids = all.map do |ssg|
        return unless ssg.os_major_version == os_major_version

        if ssg.version == ssg_version
          [ssg.version, [ref_id]]
        else
          [ssg.version, []]
        end
      end.compact.to_h

      i = all.find_index do |ssg|
        ssg.os_major_version == os_major_version && ssg.version == ssg_version
      end

      all.dig(i, 'profiles', ref_id, 'old_names')

      require 'pry'; binding.pry

      all.each_with_index.map do |ssg, i|
        if ssg.version == ssg_version &&
            ssg.os_major_version == os_major_version
          {ssg_version: all[i-1].version,
           ref_ids: ssg.dig('profiles', ref_id, 'old_names')}
        end
      end.compact
    end

    def versions
      all.map(&:version).uniq
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
