# frozen_string_literal: true

module Xccdf
  # Methods related to finding Tailorings
  module Tailorings
    def tailoring
      @tailoring = ::V2::Tailoring.find_by(
        policy: @policy,
        os_minor_version: @system.os_minor_version.to_i
      )
    end

    def external_report?
      @policy.nil?
    end

    private

    def tailored_profile
      @tailored_profile ||= tailoring.profile
    end
  end
end
