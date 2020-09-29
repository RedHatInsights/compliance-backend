# frozen_string_literal: true

# Remediation necessities for a Rule
module RuleRemediation
  extend ActiveSupport::Concern

  def remediation_issue_id
    # FIXME: Nondetermenistic canonical selection
    profile = profiles.select(&:canonical?)&.first
    return unless profile

    "ssg:rhel7|#{profile.short_ref_id}|#{ref_id}"
  end
end
