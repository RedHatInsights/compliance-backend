# frozen_string_literal: true

module Xccdf
  # Methods related to finding and auto-creating Tailorings during report parsing
  module Tailorings
    def tailoring
      @tailoring ||= find_or_create_tailoring # rubocop:disable Rails/FindByOrAssignmentMemoization
    end

    def external_report?
      @policy.nil?
    end

    def version_mismatched?
      return false unless tailoring

      security_guide.id != tailoring.profile.security_guide_id
    end

    def tailored_profile
      unless tailoring
        raise ::XccdfReportParser::OSVersionMismatch,
              "No tailoring found for policy #{@policy&.id} and OS minor version " \
              "#{@system.os_minor_version}. The system OS version may have changed " \
              'after policy assignment.'
      end

      @tailored_profile ||= tailoring.profile
    end

    private

    def find_or_create_tailoring
      os_minor = @system.os_minor_version.to_i

      tailoring = ::Tailoring.find_or_create_by!(policy: @policy, os_minor_version: os_minor) do |t|
        profile = @policy.profile.variant_for_minor(os_minor)
        t.profile = profile
        t.value_overrides = profile.value_overrides
      end

      log_tailoring_creation(tailoring, os_minor)
      tailoring
    rescue ::Exceptions::OSMinorVersionNotSupported
      nil
    end

    def log_tailoring_creation(tailoring, os_minor)
      return unless tailoring.previously_new_record?

      Rails.logger.audit_success("Auto-created tailoring for policy #{@policy.id} " \
                                 "and OS minor version #{os_minor}")
    end
  end
end
