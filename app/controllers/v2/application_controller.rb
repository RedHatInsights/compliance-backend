# frozen_string_literal: true

module V2
  # General controller to include all-encompassing behavior
  class ApplicationController < ::ActionController::API
    include ::ActionController::Helpers
    include ::Pundit::Authorization
    include V2::Authentication
    include ::ExceptionNotifierCustomData
    include V2::Metadata
    include V2::Pagination
    include V2::Collection
    include V2::Resolver
    include V2::Rendering
    include V2::ParameterHandling
    include ::ErrorHandling

    before_action :set_csp_hsts
    before_action :prod_lockdown

    class << self
      def permission_for_action(action, permission)
        @action_permissions ||= {}
        @action_permissions[action.to_sym] ||= permission
      end
    end

    # This method is being called before any before_action callbacks and it can set
    # payload information for the metrics collector.
    #
    # https://github.com/yabeda-rb/yabeda-rails#custom-tags
    def append_info_to_payload(payload)
      super

      return if identity_header.blank?

      payload[:qe] = OpenshiftEnvironment.qe_account?(identity_header.org_id)
      # payload[:path] = obfuscate_path
      payload[:source] = request_source
    end

    protected

    def audit_success(msg)
      Rails.logger.audit_success(msg)
    end

    # :nocov:
    def prod_lockdown
      return if !Rails.env.production? || ENV.fetch('ENABLE_API_V2', false).present? || org_passthrough?

      raise ActiveRecord::RecordNotFound
    end

    def org_passthrough?
      ENV.fetch('API_V2_ORG_IDS', '').split('|').include?(identity_header.org_id)
    end
    # :nocov:

    def set_csp_hsts
      response.set_header('Content-Security-Policy', "default-src 'none'")
      response.set_header('Strict-Transport-Security', "max-age=#{1.year}")
    end

    def rbac_allowed?
      return valid_cert_auth? if identity_header.cert_based?

      permission = self.class.instance_variable_get(:@action_permissions)[action_name.to_sym]
      user.authorized_to?(Rbac::INVENTORY_HOSTS_READ) && user.authorized_to?(permission)
    end

    def pundit_scope(res = resource)
      Pundit.policy_scope(current_user, res)
    end

    # Iterate through the `request.path` and replace any occurrences of identifiers.
    def obfuscate_path
      request.path.split('/').map do |chunk|
        if UUID.validate(chunk) || chunk =~ /^[0-9]+$/ || chunk =~ /^xccdf_org/
          ':id'
        else
          chunk
        end
      end.join('/')
    end

    # Determine where the request is coming from
    def request_source
      return 'insights-frontend' if request.headers['X-RH-FRONTEND-ORIGIN']
      return 'insights-client' if identity_header.cert_based?

      'basic'
    end

    # Default list of additional fields to be passed to the list of selected fields
    def extra_fields
      []
    end
  end
end
