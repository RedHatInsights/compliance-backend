# frozen_string_literal: true

# Remediation necessities for a Rule
module RuleRemediation
  extend ActiveSupport::Concern

  def remediation_issue_id
    profile_ref = short_profile_ref_id
    return unless profile_ref

    "ssg:rhel7|#{profile_ref}|#{ref_id}"
  end

  private

  def short_profile_ref_id
    # FIXME: Nondetermenistic canonical selection
    profile = profiles.select(&:canonical?)&.first
    return unless profile

    short_ref_id = profile.ref_id.downcase.split(
      'xccdf_org.ssgproject.content_profile_'
    )[1]
    short_ref_id || profile.ref_id
  end
end
