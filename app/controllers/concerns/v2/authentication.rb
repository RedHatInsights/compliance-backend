# frozen_string_literal: true

module V2
  # Authentication logic for all controllers
  module Authentication
    extend ActiveSupport::Concern

    ALLOWED_CERT_BASED_RBAC_ACTIONS = [
      # GET /api/compliance/v2/policies
      { controller: 'policies', action: 'index', parents: [] },
      # GET /api/compliance/v2/systems/:id/policies
      { controller: 'policies', action: 'index', parents: %i[systems] },
      # PATCH /api/compliance/v2/policies/:id/systems/:id
      { controller: 'systems', action: 'update', parents: %i[policies] },
      # DELETE /api/compliance/v2/policies/:id/systems/:id
      { controller: 'systems', action: 'destroy', parents: %i[policies] },
      # GET /api/compliance/v2/policies/:id/tailorings/:os_minor_version/tailoring_file
      { controller: 'tailorings', action: 'tailoring_file', parents: %i[policy] }
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

    # :nocov:
    def unauthorized(error: 'User is not authorized to view this page')
      render(
        json: { error: "Authorization error: #{error}" },
        status: :unauthorized
      )
      false
    end
    # :nocov:

    # :nocov:
    def unauthenticated(error: 'X-RH-IDENTITY header should be provided')
      render(
        json: { error: "Authentication error: #{error}" },
        status: :forbidden
      )
      false
    end
    # :nocov:

    def user
      @user ||= User.new(account: Account.from_identity_header(identity_header))
    end

    private

    def set_authenticated_user
      User.current = user
    end

    def valid_cert_endpoint?
      ALLOWED_CERT_BASED_RBAC_ACTIONS.include?(
        controller: controller_name, action: action_name, parents: params[:parents]&.map(&:to_sym).to_a
      )
    end

    # :nocov:
    def any_inventory_hosts?
      Insights::Api::Common::HostInventory.new(b64_identity: raw_identity_header).hosts.dig('results').present?
    end
    # :nocov:

    def valid_cert_auth?
      valid_cert_endpoint? && any_inventory_hosts?
    rescue Faraday::Error => e
      Rails.logger.error(e.full_message)

      false
    end

    def raw_identity_header
      request.headers['X-RH-IDENTITY']
    end

    def identity_header
      @identity_header ||= Insights::Api::Common::IdentityHeader.new(raw_identity_header)
    end
  end
end
