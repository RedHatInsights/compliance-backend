# frozen_string_literal: true

# Error to raise if id is not available
class MissingIdError < StandardError; end
# Error to raise if the format of the report is wrong
class WrongFormatError < StandardError; end

# Takes in a path to an Xccdf file, returns all kinds of properties about it
# and saves it in our database
class XccdfReportParser
  include ::Xccdf::Util

  attr_reader :report_path, :test_result_file

  def initialize(report_contents, message)
    raise ::MissingIdError unless valid_message_format?(message)

    @b64_identity = message['b64_identity']
    @account = Account.find_or_create_by(account_number: message['account'])
    @host_inventory_id = message['id']
    @test_result_file = OpenscapParser::TestResultFile.new(report_contents)
    set_openscap_parser_data
    check_report_format
  end

  def check_report_format
    raise WrongFormatError unless @test_result_file.benchmark.id.match?(
      'xccdf_org.ssgproject.content_benchmark_'
    )
  end

  def valid_message_format?(message)
    message['id'].present?
  end

  def save_all
    Host.transaction do
      save_all_benchmark_info
      save_all_test_result_info
    end
  end
end
