# frozen_string_literal: true

require 'base64'

# Authentication logic for all controllers
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user
  end

  def authenticate_user
    unless identity_header
      return unauthenticated('X-RH-IDENTITY header should be provided')
    end

    account = Account.find_or_create_by(
      account_number: identity_header_content['account_number']
    )
    user = find_or_create_user(identity_header_content['id'], account)
    User.current = user if user.valid?
  rescue JSON::ParserError
    unauthenticated 'Error parsing the X-RH-IDENTITY header'
  end

  def unauthenticated(error)
    render(
      json: { error: "Authentication error: #{error}" },
      status: :unauthorized
    )
  end

  def identity_header
    request.headers['X-RH-IDENTITY']
  end

  def identity_header_content
    JSON.parse(Base64.decode64(identity_header))
  end

  def find_or_create_user(redhat_id, account)
    user = User.find_by(redhat_id: redhat_id)
    if user.present?
      user.update account: account
    else
      user = create_user
    end
    logger.info "User authentication SUCCESS: #{user}"
    user
  end

  private

  def create_user
    if (user = User.from_x_rh_identity(identity_header_content)).save
      logger.info "User authentication SUCCESS - creating user: #{user}"
    else
      logger.info(
        "User authentication FAILED - could not create user: #{user.errors}"
      )
      unauthenticated('Could not create user with X-RH-IDENTITY contents')
    end
    user
  end
end
