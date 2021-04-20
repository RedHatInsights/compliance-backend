# frozen_string_literal: true

module Xccdf
  # Methods related to saving Hosts from openscap_parser
  module Hosts
    def host_profile
      @host_profile ||= test_result_profile.clone_to(
        policy: Policy.with_hosts(@host)
                      .with_ref_ids(test_result_profile.ref_id)
                      .find_by(account: @account),
        account: @account,
        os_minor_version: @host.os_minor_version.to_s
      )
    end
    alias save_host_profile host_profile

    def external_report?
      Policy.with_hosts(@host).with_ref_ids(test_result_profile.ref_id)
            .find_by(account: @account).nil?
    end

    private

    def test_result_profile
      @test_result_profile ||= ::Profile.canonical.create_with(
        name: @test_result_file.test_result.profile_id
      ).find_or_initialize_by(
        ref_id: @test_result_file.test_result.profile_id,
        benchmark: benchmark
      )
    end
  end
end
