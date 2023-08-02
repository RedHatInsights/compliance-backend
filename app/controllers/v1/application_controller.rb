# frozen_string_literal: true

module V1
  # Superclass for all V1 controllers
  class ApplicationController < ::ApplicationController
    def rbac_allowed?
      return valid_cert_auth? if identity_header.cert_based?

      permission = self.class.instance_variable_get(:@action_permissions)[action_name.to_sym]
      user.authorized_to?(Rbac::INVENTORY_HOSTS_READ) && user.authorized_to?(permission)
    end
  end
end
