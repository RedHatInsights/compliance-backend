# frozen_string_literal: true

require 'test_helper'
require 'audit_log/audit_log'

class AuditLogFormatterTest < ActiveSupport::TestCase
  setup do
    @formatter = Insights::API::Common::AuditLog::Formatter.new
  end

  test 'formats message string into JSON' do
    line = @formatter.call('info', Time.zone.now, 'prog', 'Audit message')

    log_msg = JSON.parse(line)
    assert_equal 'Audit message', log_msg['message']
  end

  test 'formats message with additional evidence into JSON' do
    msg = {
      message: 'Audit message',
      account_number: '12345',
      remote_ip: '172.1.2.3'
    }
    line = @formatter.call('info', Time.zone.now, 'prog', msg)

    log_msg = JSON.parse(line)
    assert_equal 'Audit message', log_msg['message']
    assert_equal '12345', log_msg['account_number']
    assert_equal '172.1.2.3', log_msg['remote_ip']
  end
end
