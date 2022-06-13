# frozen_string_literal: true

# Remediation necessities for a Rule
module RuleRemediation
  extend ActiveSupport::Concern

  # It is recommended to prefetch profiles with their benchmarks:
  #
  #  `.includes(profiles: :benchmark)`
  #
  def remediation_issue_id
    return nil unless remediation_available

    # FIXME: Nondetermenistic canonical selection
    profile = profiles.select(&:canonical?)&.first
    return unless profile

    "ssg:rhel#{profile.os_major_version}|#{profile.short_ref_id}|#{ref_id}"
  end
end
