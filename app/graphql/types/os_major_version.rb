# frozen_string_literal: true

module Types
  # This type defined supported OS major versions
  class OsMajorVersion < Types::BaseObject
    model_class ::OsMajorVersion
    graphql_name 'OsMajorVersion'
    description 'Major version of a supported operating system'

    field :os_major_version, Int, null: false
    field :profiles, [::Types::Profile], null: true

    enforce_rbac Rbac::COMPLIANCE_VIEWER
  end
end
