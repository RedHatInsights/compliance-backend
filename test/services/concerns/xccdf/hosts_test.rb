# frozen_string_literal: true

require 'test_helper'
require 'xccdf/util'
require 'xccdf/hosts'

module Xccdf
  # A class to test Xccdf::Hosts
  class HostsTest < ActiveSupport::TestCase
    class MockParser
      include Xccdf::Util

      def initialize(test_result_file:, host:, account:)
        @test_result_file = test_result_file
        @host = host
        @account = account
        @inventory_host = OpenStruct.new(id: @host.id, fqdn: @host.name)
        set_openscap_parser_data
      end
    end

    setup do
      @parser = MockParser.new(
        test_result_file: OpenscapParser::TestResultFile.new(
          file_fixture('ssg-rhel7-ds-tailored.xml').read
        ),
        host: hosts(:one),
        account: accounts(:one)
      )
    end

    test 'associate_rules_from_rule_results' do
      @parser.save_all_benchmark_info
      @parser.save_host
      @parser.save_profile_host
      @parser.save_test_result
      @parser.save_rule_results

      assert_difference('ProfileRule.count', 5) do
        @parser.associate_rules_from_rule_results
      end

      assert_difference('ProfileRule.count', 0) do
        @parser.associate_rules_from_rule_results
      end
    end
  end
end
