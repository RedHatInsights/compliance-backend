# frozen_string_literal: true

require 'yaml'

# rubocop:disable Metrics/BlockLength
SupportedSsg = Struct.new(:id, :package, :version, :upstream_version, :profiles,
                          :os_major_version, :os_minor_version,
                          keyword_init: true) do
  self::SUPPORTED_FILE = Rails.root.join('config/supported_ssg.yaml')

  class << self
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
