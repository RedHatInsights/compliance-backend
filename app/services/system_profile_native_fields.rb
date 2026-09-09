# frozen_string_literal: true

# rubocop:disable Style/Documentation
class SystemProfileNativeFields
  # rubocop:enable Style/Documentation
  Result = Data.define(
    :owner_id,
    :os_major_version,
    :os_minor_version,
    :malformed_owner_id,
    :malformed_os_major,
    :malformed_os_minor
  ) do
    def native_attributes
      {
        owner_id: owner_id,
        os_major_version: os_major_version,
        os_minor_version: os_minor_version
      }
    end

    def malformed_owner_id?
      malformed_owner_id
    end

    def malformed_os_major?
      malformed_os_major
    end

    def malformed_os_minor?
      malformed_os_minor
    end
  end

  class << self
    # rubocop:disable Metrics/MethodLength
    def normalize(system_profile)
      profile = system_profile.is_a?(Hash) ? system_profile : {}
      owner_id, malformed_owner_id = normalize_owner(profile['owner_id'])
      os_values = normalize_operating_system(profile['operating_system'])

      Result.new(
        owner_id: owner_id,
        os_major_version: os_values.fetch(:major),
        os_minor_version: os_values.fetch(:minor),
        malformed_owner_id: malformed_owner_id,
        malformed_os_major: os_values.fetch(:malformed_major),
        malformed_os_minor: os_values.fetch(:malformed_minor)
      )
    end
    # rubocop:enable Metrics/MethodLength

    private

    def normalize_owner(owner_id)
      return [nil, false] if owner_id.nil?

      return [nil, true] unless owner_id.is_a?(String) && UUID.validate(owner_id)

      type = System.type_for_attribute(:owner_id)
      serialized = type.serialize(owner_id)
      compatible = serialized.nil? ? nil : type.cast(serialized)
      [compatible.nil? ? nil : owner_id, compatible.nil?]
    end

    def normalize_operating_system(operating_system)
      return absent_operating_system if operating_system.nil?
      return malformed_operating_system unless operating_system.is_a?(Hash)

      major, malformed_major = cast_os_value(:os_major_version, operating_system['major'])
      minor, malformed_minor = cast_os_value(:os_minor_version, operating_system['minor'])
      {
        major: major,
        minor: minor,
        malformed_major: malformed_major,
        malformed_minor: malformed_minor
      }
    end

    def cast_os_value(column, source)
      value = System.type_for_attribute(column).cast(source)
      [value, !source.nil? && value.nil?]
    end

    def absent_operating_system
      { major: nil, minor: nil, malformed_major: false, malformed_minor: false }
    end

    def malformed_operating_system
      { major: nil, minor: nil, malformed_major: true, malformed_minor: true }
    end
  end
end
