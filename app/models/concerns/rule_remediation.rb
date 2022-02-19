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

    if attributes['profile_ref_id'] # use the cached profile_ref_id if available
      "ssg:rhel#{benchmark.os_major_version}|#{ShortRefId.short_ref_id(attributes['profile_ref_id'])}|#{ref_id}"
    else # select the first canonical profile if there's a cache miss
      profile = profiles.select(&:canonical?)&.first
      return unless profile

      "ssg:rhel#{profile.os_major_version}|#{profile.short_ref_id}|#{ref_id}"
    end
  end
end
