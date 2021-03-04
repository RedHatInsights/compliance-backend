# frozen_string_literal: true

require 'test_helper'
require 'audit_log/audit_log'

class AuditLogFormatterTest < ActiveSupport::TestCase
  setup do
    @formatter = Insights::API::Common::AuditLog::Formatter.new
  end

  test 'formats message string into JSON' do
    line = @formatter.call('INFO', Time.zone.now, 'prog', 'Audit message')

    log_msg = JSON.parse(line)
    assert_equal 'Audit message', log_msg['message']
  end

  test 'formats message with additional evidence into JSON' do
    msg = {
      message: 'Audit message',
      account_number: '12345',
      remote_ip: '172.1.2.3'
    }
    line = @formatter.call('INFO', Time.zone.now, 'prog', msg)

    log_msg = JSON.parse(line)
    assert_equal 'Audit message', log_msg['message']
    assert_equal '12345', log_msg['account_number']
    assert_equal '172.1.2.3', log_msg['remote_ip']
  end

  context 'sidekiq' do
    setup do
      @test_sidekiq = !Module.const_defined?(:Sidekiq)
      @sidekiq_module = if @test_sidekiq
                          Object.const_set('Sidekiq', Module.new)
                        else
                          @sidekiq_module = Sidekiq
                        end
    end

    teardown do
      Object.send(:remove_const, :Sidekiq) if @test_sidekiq
    end

    should 'log sidekiq job id from Sidekiq::Context' do
      orig_ctx_module = @sidekiq_module.const_defined?(:Context) \
                         && @sidekiq_module::Context
      ctx_module = Module.new
      @sidekiq_module.const_set('Context', ctx_module)

      begin
        ctx_module.stubs(:current).returns(jid: '123')
        assert Sidekiq::Context.current

        line = @formatter.call('info', Time.zone.now, 'prog', 'Audit message')
        log_msg = JSON.parse(line)
        assert_equal '123', log_msg['transaction_id']
      ensure
        @sidekiq_module.send(:remove_const, :Context)
        @sidekiq_module.const_set('Context', orig_ctx_module) if orig_ctx_module
      end
    end

    should 'log sidekiq job id from thread local context' do
      begin
        Thread.current[:sidekiq_context] =
          ['AppJob JID-f7568a74a93aaa8d17d5f3a4']

        line = @formatter.call('info', Time.zone.now, 'prog', 'Audit message')
        log_msg = JSON.parse(line)
        assert_equal 'f7568a74a93aaa8d17d5f3a4', log_msg['transaction_id']
      ensure
        Thread.current[:sidekiq_context] = nil
      end
    end
  end
end
