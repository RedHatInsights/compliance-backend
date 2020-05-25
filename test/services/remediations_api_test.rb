# frozen_string_literal: true

require 'test_helper'
require 'remediations_api'

class RemediationsAPITest < ActiveSupport::TestCase
  setup do
    @rule = rules(:one)
    @rule.profiles << profiles(:one)
  end

  test 'import_remediations succeeds and updates all rules' do
    assert_not @rule.remediation_available
    response_body = {
      "ssg:rhel7|profile|#{@rule.ref_id}": {
        'id': 'ssg:rhel7|profile|rule',
        'resolution_risk': -1,
        'resolutions': [
          {
            'description': 'Uninstall rsh Package',
            'id': 'fix',
            'needs_reboot': true,
            'resolution_risk': -1
          }
        ]
      }
    }.to_json
    test_conn = ::Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.post('/api/remediations/v1/resolutions') do
          [
            200,
            { 'Content-Type': 'text/plain' },
            response_body
          ]
        end
      end
    end
    Platform.stubs(:connection).returns(test_conn)
    assert_not @rule.remediation_available
    RemediationsAPI.new(accounts(:test)).import_remediations
    assert @rule.reload.remediation_available
  end

  test 'import_remediations request fails' do
    @connection = mock('faraday_connection')
    Platform.stubs(:connection).returns(@connection)
    assert_not @rule.remediation_available
    @connection.expects(:post).raises(Faraday::ClientError, '400 error')
    RemediationsAPI.new(accounts(:test)).import_remediations
    assert_not @rule.reload.remediation_available
  end
end
