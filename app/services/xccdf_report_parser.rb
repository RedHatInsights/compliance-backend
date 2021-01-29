# frozen_string_literal: true

# Takes in a path to an Xccdf file, returns all kinds of properties about it
# and saves it in our database
class XccdfReportParser
  # Error to raise if id is not available
  class MissingIdError < StandardError; end
  # Error to raise if the format of the report is wrong
  class WrongFormatError < StandardError; end
  # Error to raise if the OS version does not match benchmark's
  class OSVersionMismatch < StandardError; end
  # Error to raise if the incoming report belongs to no known policy
  class ExternalReportError < StandardError; end
  # Error to raise if the incoming report belongs to no known benchmark
  class UnknownBenchmarkError < StandardError; end
  # Error to raise if the incoming report belongs to no known profile
  class UnknownProfileError < StandardError; end
  # Error to raise if the incoming report contains an unknown rule
  class UnknownRuleError < StandardError; end

  ERRORS = [
    MissingIdError, WrongFormatError, OSVersionMismatch,
    ActiveRecord::RecordInvalid, ExternalReportError, UnknownBenchmarkError,
    UnknownProfileError, UnknownRuleError
  ].freeze

  include ::Xccdf::Util

  attr_reader :report_path, :test_result_file

  def initialize(report_contents, message)
    raise MissingIdError unless valid_message_format?(message)

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

  def check_os_version
    # rubocop:disable Style/GuardClause
    if benchmark.os_major_version.to_s != @host.os_major_version.to_s
      raise OSVersionMismatch,
            "OS major version (#{@host.os_major_version}) does not match with" \
            " benchmark #{benchmark.ref_id} (#{benchmark.os_major_version}). "\
            "#{parse_failure_message}"
    end
    # rubocop:enable Style/GuardClause
  end

  def check_for_external_reports
    # rubocop:disable Style/GuardClause
    if external_report?
      raise ExternalReportError,
            "No policy found matching benchmark #{benchmark.ref_id}. "\
            "#{parse_failure_message}"
    end
    # rubocop:enable Style/GuardClause
  end

  def save_missing_supported_benchmark
    save_all_benchmark_info if SupportedSsg.versions.include?(benchmark.version)
  end

  def check_for_missing_benchmark
    # rubocop:disable Style/GuardClause
    unless benchmark.persisted?
      raise UnknownBenchmarkError,
            "No benchmark found matching ref_id #{benchmark.ref_id} and "\
            "SSG #{benchmark.version}. #{parse_failure_message}"
    end
    # rubocop:enable Style/GuardClause
  end

  def check_for_missing_test_result_profile
    # rubocop:disable Style/GuardClause
    unless test_result_profile.persisted?
      raise UnknownProfileError,
            "No profile found matching ref_id #{test_result_profile.ref_id} "\
            "in benchmark #{benchmark.ref_id} with SSG "\
            "#{benchmark.version}. #{parse_failure_message}"
    end
    # rubocop:enable Style/GuardClause
  end

  def check_for_missing_rules
    # rubocop:disable Style/GuardClause
    if test_result_rules_unknown.any?
      raise UnknownRuleError,
            'The following rules are missing from profile '\
            "#{test_result_profile.ref_id} in benchmark #{benchmark.ref_id} "\
            "with SSG #{benchmark.version}:\n"\
            "#{test_result_rules_unknown.join("\n")}\n#{parse_failure_message}"
    end
    # rubocop:enable Style/GuardClause
  end

  def check_for_missing_benchmark_info
    check_for_missing_benchmark
    check_for_missing_test_result_profile
    check_for_missing_rules
  end

  def save_all
    Host.transaction do
      check_os_version
      check_for_external_reports unless Settings.features.parse_external_reports
      save_missing_supported_benchmark
      check_for_missing_benchmark_info
      save_all_test_result_info
    end
  end

  private

  def parse_failure_message
    "Report for profile #{@test_result_file.test_result.profile_id} against "\
      "#{@host.name} of account #{@account.account_number} could not be parsed."
  end
end
