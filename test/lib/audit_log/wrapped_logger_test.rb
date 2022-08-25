# frozen_string_literal: true

require 'test_helper'
require 'audit_log/audit_log'

class AuditLogWrappedLoggerTest < ActiveSupport::TestCase
  setup do
    @base_logger_output = StringIO.new
    @base_logger = Logger.new(@base_logger_output)
    @base_logger.level = Logger::DEBUG

    @output = StringIO.new
    @audit_logger = Logger.new(@output)
    @wrapped = Insights::API::Common::AuditLog::WrappedLogger.new(
      @base_logger, @audit_logger
    )
  end

  def capture_log
    assert @output.size.positive?, 'No ouput in the log'
    @output.rewind # logger seems to read what it's writing?
    JSON.parse @output.readlines[-1]
  end

  test 'logs a general audit message formatted into JSON' do
    @wrapped.audit('Audit message')
    log_msg = capture_log
    assert_equal 'Audit message', log_msg['message']
    assert_equal 'audit', log_msg['level']
  end

  test 'logs a success audit message' do
    @wrapped.audit_success('Audit success message')
    log_msg = capture_log
    assert_equal 'Audit success message', log_msg['message']
    assert_equal 'audit', log_msg['level']
    assert_equal 'success', log_msg['status']
  end

  test 'logs a fail audit message' do
    @wrapped.audit_fail('Audit fail message')
    log_msg = capture_log
    assert_equal 'Audit fail message', log_msg['message']
    assert_equal 'audit', log_msg['level']
    assert_equal 'fail', log_msg['status']
  end

  test 'logs audit with general evidence included' do
    @wrapped.audit('Audit message')
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

  test 'logs a fail audit message with additional evidence' do
    @wrapped.audit_fail(message: 'Audit fail message', controller: 'MyCtrl')
    log_msg = capture_log
    assert_equal 'Audit fail message', log_msg['message']
    assert_equal 'audit', log_msg['level']
    assert_equal 'fail', log_msg['status']
    assert_equal 'MyCtrl', log_msg['controller']
  end

  test 'other logs passed to base logger' do
    @wrapped.info('Test info to base logger')
    @wrapped.info { 'Test block passing to base logger' }
    @wrapped.debug('Test debug to base logger')
    @wrapped.warn('Test warn to base logger')
    @wrapped.error('Test error to base logger')
    @wrapped.fatal('Test fatal to base logger')

    output = @base_logger_output.string
    assert_includes output, 'info'
    assert_includes output, 'block'
    assert_includes output, 'debug'
    assert_includes output, 'warn'
    assert_includes output, 'error'
    assert_includes output, 'fatal'
  end

  test 'sends reopen to both loggers' do
    @base_logger.stubs(:reopen).at_least_once
    @audit_logger.stubs(:reopen).at_least_once
    @wrapped.reopen
  end

  test 'sends close to both loggers' do
    @base_logger.stubs(:close).at_least_once
    @audit_logger.stubs(:close).at_least_once
    @wrapped.close
  end

  test 'supports Rails broadcasting' do
    base_logger = ActiveSupport::Logger.new(StringIO.new)
    wrapped = Insights::API::Common::AuditLog::WrappedLogger.new(
      base_logger, @audit_logger
    )

    secondary_output = StringIO.new
    secondary = ActiveSupport::Logger.new(secondary_output)
    wrapped.extend(ActiveSupport::Logger.broadcast(secondary))

    wrapped.info('Test broadcast')
    assert_includes secondary_output.string, 'Test broadcast'
  end

  test 'missing methods passed to base logger' do
    @wrapped << 'RAW MESSAGE'

    output = @base_logger_output.string
    assert_includes output, 'RAW MESSAGE'
  end

  test 'raises NameError if missing also on base logger' do
    assert_raises NameError do
      @wrapped.non_existent_method
    end
  end

  test 'setting account org_id' do
    begin
      @wrapped.audit_with_account('1')
      @wrapped.audit('Audit message')
      log_msg = capture_log
      assert_equal '1', log_msg['org_id']

      @wrapped.audit_with_account('2') do
        @wrapped.audit('Audit message')
        log_msg = capture_log
        assert_equal '2', log_msg['org_id']
      end

      @wrapped.audit_with_account(nil)
      @wrapped.audit('Audit message')
      log_msg = capture_log
      assert_not log_msg['org_id']
    ensure
      @wrapped.audit_with_account(nil)
    end
  end
end
