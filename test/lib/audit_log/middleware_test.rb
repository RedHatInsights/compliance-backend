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
    @audit = Insights::API::Common::AuditLog.setup(@logger)
  end

  def capture_log
    @output.rewind # logger seems to read what it's writing?
    JSON.parse @output.readlines[-1]
  end

  test 'log successful request' do
    app = MockRackApp.new
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 200 OK', log_msg['message']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'info', log_msg['level']
  end

  test 'log forbidden request' do
    app = MockRackApp.new([403, {}, ['Forbidden Access']])
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 403 Forbidden', log_msg['message']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'warning', log_msg['level']
  end

  test 'log error request' do
    app = MockRackApp.new([500, {}, ['some Server Error']])
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 500 Internal Server Error', log_msg['message']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'err', log_msg['level']
  end

  test 'capture process_action' do
    app = MockRackApp.new(
      [200, {}, ['OK']],
      ['process_action.action_controller', { controller: 'MyController',
                                             action: 'index' }]
    )
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_equal 'GET / -> 200 OK', log_msg['message']
    assert_equal 'MyController#index', log_msg['controller']
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'info', log_msg['level']
  end

  test 'capture halted_callback' do
    app = MockRackApp.new(
      [400, {}, ['Bad Request']],
      ['halted_callback.action_controller', { filter: 'halting_filter' }]
    )
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_includes log_msg['message'], 'GET / -> 400 Bad Request'
    assert_includes log_msg['message'], 'filter chain halted by :halting_filter'
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'warning', log_msg['level']
  end

  test 'capture unpermitted_parameters' do
    app = MockRackApp.new(
      [400, {}, ['Bad Request']],
      ['unpermitted_parameters.action_controller', { keys: ['paramname'] }]
    )
    mw = Insights::API::Common::AuditLog::Middleware.new(app)
    request = Rack::MockRequest.new(mw)

    request.get('/', 'HTTP_X_FORWARDED_FOR' => '172.1.2.3')

    log_msg = capture_log
    assert_includes log_msg['message'], 'GET / -> 400 Bad Request'
    assert_includes log_msg['message'], 'unpermitted params :paramname'
    assert_equal '172.1.2.3', log_msg['remote_ip']
    assert_equal 'warning', log_msg['level']
  end
end
