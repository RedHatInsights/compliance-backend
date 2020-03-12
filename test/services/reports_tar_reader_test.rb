# frozen_string_literal: true

require 'test_helper'

class ReportsTarReaderTest < ActiveSupport::TestCase
  test 'extracts reports properly from the tar' do
    assert_nothing_raised do
      file = File.new(file_fixture('insights-archive.tar.gz'))
      reports = ReportsTarReader.new(file).reports
      reports.each do |report|
        XccdfReportParser.new(
          report,
          'account' => accounts(:test).account_number,
          'id' => ::UUID.generate,
          'b64_identity' => 'b64_fake_identity',
          'metadata' => {
            'fqdn' => 'lenovolobato.lobatolan.home'
          }
        )
      end
    end
  end
end
