# frozen_string_literal: true

module Xccdf
  # Methods related to saving Hosts from openscap_parser
  module Hosts
    def tailoring
      @tailoring ||= V2::Tailoring.find_or_create_by!(
        policy: policy,
        os_minor_version: @system.os_minor_version
      ) do |t|
        t.profile = canonical_profile.variant_for_minor(@system.os_minor_version)
        t.value_overrides = t.profile.value_overrides
      end
    end
    # FIXME: V2 compatibility alias - remove after V2 report parsing refactor
    alias save_host_profile tailoring

    def external_report?
      policy.nil?
    end

    private

    def canonical_profile
      @canonical_profile ||= V2::Profile.find_by!(
        ref_id: @test_result_file.test_result.profile_id,
        security_guide_id: security_guide.id
      )
    end
    # FIXME: V2 compatibility alias - remove after V2 report parsing refactor
    alias test_result_profile canonical_profile

    def policy
      @policy ||= V2::Policy.joins(:profile, :policy_systems)
                            .find_by(
                              profile: { ref_id: canonical_profile.ref_id },
                              policy_systems: { system_id: @host.id },
                              account: @account
                            )
    end
  end
end
