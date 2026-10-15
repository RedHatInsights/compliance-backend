# frozen_string_literal: true

module ClowderV2Helpers
  module_function

  def resolve_rbac_endpoint
    endpoint = v2_settings
    if endpoint.present?
      v2_rbac_result(endpoint)
    else
      v1_rbac_result
    end
  end

  def v2_rbac_result(endpoint)
    {
      url: endpoint.url,
      host: endpoint.host,
      scheme: endpoint.scheme,
      ca_certificate: endpoint.ca_certificate,
      authenticated: endpoint.authenticated == true,
      source: :v2
    }
  end

  def v1_rbac_result
    {
      url: Settings.endpoints.rbac.url,
      host: Settings.endpoints.rbac.host,
      scheme: Settings.endpoints.rbac.scheme,
      ca_certificate: nil,
      authenticated: false,
      source: :v1
    }
  end

  def v2_settings
    Settings.v2_endpoints&.rbac&.service
  rescue NoMethodError
    nil
  end
end
