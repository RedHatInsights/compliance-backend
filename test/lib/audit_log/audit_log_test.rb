# frozen_string_literal: true

require 'test_helper'
require 'audit_log/audit_log'

class AuditLogTest < ActiveSupport::TestCase
  setup do
    @output = StringIO.new
    @logger = Logger.new(@output)
    @audit = Insights::API::Common::AuditLog.setup(@logger)
  end

  def capture_log(msg)
    @audit.logger.info(msg)
    @output.rewind # logger seems to read what it's writing?
    JSON.parse @output.readlines[-1]
  end

  test 'logs a general message formatted into JSON' do
    log_msg = capture_log('Audit message')
    assert_equal 'Audit message', log_msg['message']
    assert_equal 'audit', log_msg['level']
  end

  test 'logs include general evidence' do
    @audit.logger.info('Audit message')
    line = @output.string
    assert line

    log_msg = JSON.parse(line).compact
    assert_equal log_msg.keys.sort, %w[
      @timestamp
      hostname
      pid
      thread_id
      level
      transaction_id
      message
    ].sort
  end

  test 'setting account number' do
    begin
      @audit.with_account('1')
      log_msg = capture_log('Audit message')
      assert_equal '1', log_msg['account_number']

      @audit.with_account('2') do
        log_msg = capture_log('Audit message')
        assert_equal '2', log_msg['account_number']
      end

      log_msg = capture_log('Audit message')
      assert_equal '1', log_msg['account_number']

      @audit.with_account(nil)
      log_msg = capture_log('Audit message')
      assert_not log_msg['account_number']
    ensure
      @audit.with_account(nil)
    end
  end
end
