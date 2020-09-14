# frozen_string_literal: true

# Remediation necessities for a Rule
module RuleRemediation
  extend ActiveSupport::Concern

  def remediation_issue_id
    "ssg:rhel7|#{short_profile_ref_id}|#{ref_id}"
  end

  private

  def short_profile_ref_id
    profile = profiles.canonical.first
    short_ref_id = profile.ref_id.downcase.split(
      'xccdf_org.ssgproject.content_profile_'
    )[1]
    short_ref_id || profile.ref_id
  end
end
