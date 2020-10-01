# frozen_string_literal: true

# JSON API serialization of Supported SSGs
class SupportedSsgSerializer
  include FastJsonapi::ObjectSerializer
  attributes :package, :version, :os_major_version, :os_minor_version

  attribute :profiles do |obj|
    obj.profiles&.keys
  end
end
