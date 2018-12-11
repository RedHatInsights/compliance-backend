# frozen_string_literal: true

require 'base64'

# Authentication logic for all controllers
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user
  end

  def authenticate_user
    return unauthenticated unless identity_header

    account = Account.find_or_create_by(
      account_number: identity_header_content['account_number']
    )
    user = find_or_create_user(identity_header_content['user']['username'],
                               account)
    return if performed? || !user.persisted?

    User.current = user
  rescue JSON::ParserError
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

  def identity_header
    request.headers['X-RH-IDENTITY']
  end

  def identity_header_content
    JSON.parse(Base64.decode64(identity_header))['identity']
  end

  def find_or_create_user(username, account)
    user = User.find_by(username: username, account: account)
    if user.present?
      logger.info "User authentication SUCCESS: #{identity_header_content}"
    else
      user = create_user
    end
    user
  end

  private

  def create_user
    if (user = User.from_x_rh_identity(identity_header_content)).save
      logger.info 'User authentication SUCCESS - creating user: '\
        "#{identity_header_content}"
    else
      logger.info 'User authentication FAILED - could not create user: '\
        "#{user.errors.full_messages}"
      unauthenticated('Could not create user with X-RH-IDENTITY contents')
    end
    user
  end
end
