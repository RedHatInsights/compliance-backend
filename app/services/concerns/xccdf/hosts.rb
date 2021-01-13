# frozen_string_literal: true

module Xccdf
  # Methods related to saving Hosts from openscap_parser
  module Hosts
    def save_host
      @host = ::Host.find_or_initialize_by(id: inventory_host['id'],
                                           account_id: @account.id)
      @host.update_from_inventory_host!(inventory_host)
    end

    def host_profile
      @host_profile ||= test_result_profile.clone_to(
        policy: Policy.with_hosts(@host)
                      .with_ref_ids(test_result_profile.ref_id)
                      .find_by(account: @account),
        account: @account
      )
    end
    alias save_host_profile host_profile

    def associate_rules_from_rule_results
      ::ProfileRule.import!(
        ::Rule.where(
          ref_id: selected_op_rule_results.map(&:id),
          benchmark_id: @benchmark.id
        ).pluck(:id).map do |rule_id|
          ::ProfileRule.new(profile_id: @host_profile.id,
                            rule_id: rule_id)
        end, ignore: true
      )
    end

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

    def inventory_host
      @inventory_host ||= ::HostInventoryApi.new(
        @account,
        ::Settings.host_inventory_url,
        @b64_identity
      ).inventory_host(@host_inventory_id)
    end
  end
end
