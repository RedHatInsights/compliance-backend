# frozen_string_literal: true

module V1
  # Superclass for all V1 controllers
  class ApplicationController < ::ApplicationController
    before_action :add_deprecation_warning

    def rbac_allowed?
      return valid_cert_auth? if identity_header.cert_based?

      permission = self.class.instance_variable_get(:@action_permissions)[action_name.to_sym]
      user.authorized_to?(Rbac::INVENTORY_HOSTS_READ) && user.authorized_to?(permission)
    end

    private

    def add_deprecation_warning
      response.set_header('Deprecation', '@1754611200')
      response.set_header('Sunset', '@1757030400')
      response.set_header('Link', '<https://console.redhat.com/docs/api/compliance/v2>; rel="successor-version"')
    end
  end
end
