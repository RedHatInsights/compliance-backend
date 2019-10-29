# frozen_string_literal: true

require 'test_helper'
require 'remediations_api'

class RemediationsAPITest < ActiveSupport::TestCase
  setup do
    @rule = rules(:one)
    @rule.profiles << profiles(:one)
    @connection = mock('faraday_connection')
    Platform.stubs(:connection).returns(@connection)
  end

  test 'import_remediations succeeds and updates all rules' do
    assert_not @rule.remediation_available
    response = OpenStruct.new(body: {
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
    }.to_json)
    @connection.expects(:post).returns(response)
    RemediationsAPI.new(accounts(:test)).import_remediations
    assert @rule.reload.remediation_available
  end

  test 'import_remediations request fails' do
    assert_not @rule.remediation_available
    @connection.expects(:post).raises(Faraday::ClientError, '400 error')
    RemediationsAPI.new(accounts(:test)).import_remediations
    assert_not @rule.reload.remediation_available
  end
end
