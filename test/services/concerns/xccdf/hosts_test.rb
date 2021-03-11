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
  end
end
