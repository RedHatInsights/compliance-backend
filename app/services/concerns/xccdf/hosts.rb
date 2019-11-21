# frozen_string_literal: true

module Xccdf
  # Methods related to saving Hosts from openscap_parser
  module Hosts
    def save_host
      @host = ::Host.find_or_initialize_by(id: inventory_host['id'],
                                           account_id: @account.id)
      @host.update!(name: inventory_host['fqdn'])
    end

    def save_profile_host
      test_result_profile.clone_to(account: @account, host: @host)
    end

    def report_host
      @metadata&.dig('fqdn') || @test_result_file.host
    end

    private

    def test_result_profile
      ::Profile.canonical
        .find_by(ref_id: @test_result_file.test_result.profile_id,
                 benchmark: @benchmark)
    end

    def inventory_host
      @inventory_host ||= ::HostInventoryAPI.new(
        @host_inventory_id,
        report_host,
        @account,
        ::Settings.host_inventory_url,
        @b64_identity
      ).inventory_host
    end
  end
end
