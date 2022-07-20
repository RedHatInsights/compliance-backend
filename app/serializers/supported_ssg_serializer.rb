# frozen_string_literal: true

# JSON API serialization of Supported SSGs
class SupportedSsgSerializer < ApplicationSerializer
  attributes :package, :version, :os_major_version, :os_minor_version

  attribute :profiles do |obj|
    obj.profiles&.keys
  end

  # Hacky fix that prevents the serializer to fail with no relationships
  @relationships_to_serialize = {}
end
