# frozen_string_literal: true

require 'audit_log/audit_log'

class AuditLogMiddlewareTest < ActiveSupport::TestCase
  class MockRackApp
    attr_reader :request_body

    def initialize(response = nil, instrumentation = nil)
      @request_headers = {}
      @response = response || [200, {}, ['OK']]
      @instrumentation = instrumentation
    end

    def call(env)
      @env = env
      @request_body = env['rack.input'].read
      if @instrumentation
        ActiveSupport::Notifications.instrument(*@instrumentation)
      end
      @response
    end

    def [](key)
      @env[key]
    end
  end

  setup do
    @output = StringIO.new
    @logger = Logger.new(@output)
    @audit = Insights::API::Common::AuditLog.new(nil, @logger)
  end

  def capture_log
    assert @output.size.positive?, 'No ouput in the log'
    @output.rewind # logger seems to read what it's writing?
    JSON.parse @output.readlines[-1]
  end

  test 'log successful request' do
    app = MockRackApp.new
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = @audit
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 200 OK', log_msg['message']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'success', log_msg['status']
  end

  test 'log forbidden request' do
    app = MockRackApp.new([403, {}, ['Forbidden Access']])
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = @audit
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 403 Forbidden', log_msg['message']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'fail', log_msg['status']
  end

  test 'log error request' do
    app = MockRackApp.new([500, {}, ['some Server Error']])
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = @audit
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 500 Internal Server Error', log_msg['message']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'fail', log_msg['status']
  end

  test 'capture process_action' do
    app = MockRackApp.new(
      [200, {}, ['OK']],
      ['process_action.action_controller', { controller: 'MyController',
                                             action: 'index' }]
    )
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = @audit
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 200 OK', log_msg['message']
    assert_equal 'MyController#index', log_msg['controller']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'success', log_msg['status']
  end

  test 'capture halted_callback' do
    app = MockRackApp.new(
      [400, {}, ['Bad Request']],
      ['halted_callback.action_controller', { filter: 'halting_filter' }]
    )
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = @audit
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_includes log_msg['message'], 'GET / -> 400 Bad Request'
    assert_includes log_msg['message'], 'filter chain halted by :halting_filter'
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'fail', log_msg['status']
  end

  test 'capture unpermitted_parameters' do
    app = MockRackApp.new(
      [400, {}, ['Bad Request']],
      ['unpermitted_parameters.action_controller', { keys: ['paramname'] }]
    )
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = @audit
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_includes log_msg['message'], 'GET / -> 400 Bad Request'
    assert_includes log_msg['message'], 'unpermitted params :paramname'
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'fail', log_msg['status']
  end

  test 'setting account number context' do
    app = MockRackApp.new
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = @audit
    request = Rack::MockRequest.new(mw)

    Insights::API::Common::AuditLog.audit_with_account('1234')
    request.get('/', 'HTTP_X_FORWARDED_FOR' => '127.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 200 OK', log_msg['message']
    assert_equal '1234', log_msg['account_number']
    assert_equal '127.1.2.3', log_msg['remote_ip']
    assert_equal 'success', log_msg['status']

    assert_not Thread.current[:audit_account_number],
               'account number should be reset after request is done'
  end

  test 'fallbacks to info loging' do
    basic_output = StringIO.new
    basic_logger = Logger.new(basic_output)
    app = MockRackApp.new
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    mw.logger = basic_logger
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = basic_output.string
    assert_includes log_msg, 'GET / -> 200 OK'
    assert_includes log_msg, '172.1.2.3'
    assert_includes log_msg, 'success'
  end
end
