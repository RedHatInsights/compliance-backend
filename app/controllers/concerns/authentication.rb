# frozen_string_literal: true

require 'rbac_api'

# Authentication logic for all controllers
module Authentication
  extend ActiveSupport::Concern

  ALLOWED_CERT_BASED_RBAC_ACTIONS = [
    { controller: 'profiles', action: 'index' },
    { controller: 'profiles', action: 'tailoring_file' }
  ].freeze

  included do
    before_action :authenticate_user
  end

  def authenticate_user
    return unauthenticated unless identity_header.valid?
    return unauthorized unless rbac_allowed?

    return if performed?

    User.current = user
  rescue JSON::ParserError, NoMethodError
    unauthenticated error: 'Error parsing the X-RH-IDENTITY header'
  end

  def current_user
    User.current
  end

  def unauthorized(error: 'User is not authorized to view this page')
    render(
      json: { error: "Authorization error: #{error}" },
      status: :forbidden
    )
    false
  end

  def unauthenticated(error: 'X-RH-IDENTITY header should be provided')
    render(
      json: { error: "Authentication error: #{error}" },
      status: :unauthorized
    )
    false
  end

  def user
    User.new(account: account_from_header)
  end

  def rbac_allowed?
    return true if ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)
    return valid_cert_auth? if identity_header.cert_based?

    @rbac_api ||= ::RbacApi.new(raw_identity_header)
    @rbac_api.check_user
  end

  private

  def valid_cert_endpoint?
    ALLOWED_CERT_BASED_RBAC_ACTIONS.include?(
      controller: controller_name, action: action_name
    )
  end

  def valid_cert_auth?
    valid_cert_endpoint? && HostInventoryApi.new(
      b64_identity: raw_identity_header
    ).hosts.dig('results').present?
  rescue Faraday::Error => e
    Rails.logger.error(e.full_message)

    false
  end

  def raw_identity_header
    request.headers['X-RH-IDENTITY']
  end

  def identity_header
    @identity_header ||= IdentityHeader.new(raw_identity_header)
  end

  def account_from_header
    Account.find_or_create_by(
      account_number: identity_header.identity['account_number']
    )
  end
end
