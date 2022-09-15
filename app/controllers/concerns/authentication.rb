# frozen_string_literal: true

# Authentication logic for all controllers
module Authentication
  extend ActiveSupport::Concern

  ALLOWED_CERT_BASED_RBAC_ACTIONS = [
    { controller: 'profiles', action: 'index' },
    { controller: 'profiles', action: 'tailoring_file' },
    { controller: 'rules', action: 'show' }
  ].freeze

  included do
    around_action :authenticate_user
  end

  def authenticate_user
    if identity_header.blank?
      return unauthenticated(error: 'Error parsing the X-RH-IDENTITY header')
    end
    return unauthenticated unless identity_header.valid?
    return unauthorized unless rbac_allowed?

    return if performed?

    set_authenticated_user
    yield
  ensure
    User.current = nil
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
    @user ||= User.new(account: Account.from_identity_header(identity_header))
  end

  def rbac_allowed?
    return true if ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)
    return valid_cert_auth? if identity_header.cert_based?

    @rbac_permissions ||= Rbac.load_user_permissions(raw_identity_header)

    @rbac_permissions.any? do |access|
      Rbac.verify(access.permission, Rbac::COMPLIANCE_VIEWER)
    end
  end

  private

  def set_authenticated_user
    User.current = user
    Insights::API::Common::AuditLog.audit_with_account(
      current_user.org_id
    )
  end

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
end
