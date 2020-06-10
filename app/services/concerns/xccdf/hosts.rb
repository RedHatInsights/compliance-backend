# frozen_string_literal: true

# Error to raise if the inventory host could not be found
class InventoryHostNotFound < StandardError; end

module Xccdf
  # Methods related to saving Hosts from openscap_parser
  module Hosts
    def save_host
      @host = ::Host.find_or_initialize_by(id: inventory_host['id'],
                                           account_id: @account.id)
      @host.update!(name: inventory_host['fqdn'])
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

    private

    def test_result_profile
      ::Profile.canonical
               .where(ref_id: @test_result_file.test_result.profile_id,
                      benchmark: @benchmark).first ||
        ::Profile.find_or_initialize_by(
          ref_id: @test_result_file.test_result.profile_id,
          name: @test_result_file.test_result.profile_id,
          benchmark_id: @benchmark.id
        )
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
