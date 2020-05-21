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
    return true if skip_rbac_for_cert_based_auth?

    @rbac_api ||= ::RbacApi.new(request.headers['X-RH-IDENTITY'])
    @rbac_api.check_user
  end

  private

  def skip_rbac_for_cert_based_auth?
    cert_based_auth? &&
      ALLOWED_CERT_BASED_RBAC_ACTIONS.include?(controller: controller_name,
                                               action: action_name)
  end

  def cert_based_auth?
    identity_header.identity.dig('user').nil?
  end

  def identity_header
    @identity_header ||= IdentityHeader.new(request.headers['X-RH-IDENTITY'])
  end

  def account_from_header
    Account.find_or_create_by(
      account_number: identity_header.identity['account_number']
    )
  end
end
