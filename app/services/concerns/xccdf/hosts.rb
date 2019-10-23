# frozen_string_literal: true

module Xccdf
  # Methods related to saving Hosts from openscap_parser
  module Hosts
    def save_host
      @host = Host.find_or_initialize_by(id: @host_inventory_id,
                                         account_id: @account.id)
      @host.update!(name: report_host) unless @host.name == report_host
    end

    def save_profile_host
      test_result_profile.clone_to(account: @account, host: @host)
    end

    def report_host
      @metadata&.dig('fqdn') || @test_result_file.host
    end

    private

    def test_result_profile
      @profiles.find do |profile|
        profile.ref_id == @test_result_file.test_result.profile_id
      end
    end
  end
end
