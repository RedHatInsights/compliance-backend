# frozen_string_literal: true

require 'test_helper'

class ReportsTarReaderTest < ActiveSupport::TestCase
  test 'extracts reports properly from the tar' do
    assert_nothing_raised do
      file = File.new(file_fixture('insights-archive.tar.gz'))
      account = FactoryBot.create(:account)
      host = FactoryBot.create(:host, account: account.account_number)
      reports = ReportsTarReader.new(file).reports
      assert_equal 3, reports.length
      reports.each do |report|
        XccdfReportParser.new(
          report,
          'account' => account.account_number,
          'id' => host.id,
          'b64_identity' => account.b64_identity,
          'metadata' => {
            'display_name' => 'foo.example.com'
          }
        )
      end
    end
  end

  test 'detects reports that have long filename' do
    assert_nothing_raised do
      file = File.new(file_fixture('insights-archive-long.tar.gz'))
      account = FactoryBot.create(:account)
      host = FactoryBot.create(:host, account: account.account_number)
      reports = ReportsTarReader.new(file).reports
      assert_equal 1, reports.length
      reports.each do |report|
        XccdfReportParser.new(
          report,
          'account' => account.account_number,
          'id' => host.id,
          'b64_identity' => account.b64_identity,
          'metadata' => {
            'display_name' => 'foo.example.com'
          }
        )
      end
    end
  end

  test 'omits paths that have openscap_results outside the filename' do
    assert_nothing_raised do
      file = File.new(file_fixture('insights-archive-prefixed.tar.gz'))
      reports = ReportsTarReader.new(file).reports
      assert_equal 0, reports.length
    end
  end
end
