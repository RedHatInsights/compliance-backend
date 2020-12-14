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
        account: @account, host: @host
      )
    end
    alias save_profile_host host_profile

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
      test_result_profile.find_policy(account: @account, hosts: [@host]).nil?
    end

    private

    def test_result_profile
      @test_result_profile ||= ::Profile.canonical.find_or_initialize_by(
        ref_id: @test_result_file.test_result.profile_id,
        benchmark: benchmark
      ).tap do |profile|
        profile.name ||= @test_result_file.test_result.profile_id
      end
    end

    def inventory_host
      @inventory_host ||= ::HostInventoryAPI.new(
        @account,
        ::Settings.host_inventory_url,
        @b64_identity
      ).inventory_host(@host_inventory_id)
    end
  end
end
