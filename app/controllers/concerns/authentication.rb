# frozen_string_literal: true

require 'rbac_api'

# Authentication logic for all controllers
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user
  end

  def authenticate_user
    return unauthenticated unless identity_header.valid? && rbac_allowed?

    return if performed?

    User.current = user
  rescue JSON::ParserError, NoMethodError
    unauthenticated 'Error parsing the X-RH-IDENTITY header'
  end

  def current_user
    User.current
  end

  def unauthenticated(error = 'X-RH-IDENTITY header should be provided')
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

    @rbac_api ||= ::RbacApi.new(request.headers['X-RH-IDENTITY'])
    @rbac_api.check_user
  end

  private

  def identity_header
    @identity_header ||= IdentityHeader.new(request.headers['X-RH-IDENTITY'])
  end

  def account_from_header
    Account.find_or_create_by(
      account_number: identity_header.identity['account_number']
    )
  end
end
