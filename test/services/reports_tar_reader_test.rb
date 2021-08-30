# frozen_string_literal: true

require 'test_helper'

class ReportsTarReaderTest < ActiveSupport::TestCase
  test 'extracts reports properly from the tar' do
    assert_nothing_raised do
      file = File.new(file_fixture('insights-archive.tar.gz'))
      account = FactoryBot.create(:account)
      host = FactoryBot.create(:host, account: account.account_number)
      reports = ReportsTarReader.new(file).reports
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
end
