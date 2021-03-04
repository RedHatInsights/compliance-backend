# frozen_string_literal: true

require 'manageiq/loggers'

# Common space for Insights API stuff
module Insights
  module API
    module Common
      module AuditLog
        # Audit Log formatter with evidence capture
        class Formatter < ManageIQ::Loggers::Container::Formatter
          ALLOWED_PAYLOAD_KEYS = %i[message status account_number controller
                                    remote_ip transaction_id].freeze

          # rubocop:disable Metrics/MethodLength
          def call(_, time, progname, msg)
            payload = {
              '@timestamp': format_datetime(time),
              hostname: hostname,
              pid: $PROCESS_ID,
              thread_id: thread_id,
              service: progname,
              level: 'audit',
              account_number: account_number
            }
            payload.merge!(framework_evidence)
            JSON.generate(merge_message(payload, msg).compact) << "\n"
          end
          # rubocop:enable Metrics/MethodLength

          def framework_evidence
            sidekiq_ctx = sidekiq_current_ctx
            if sidekiq_ctx
              { controller: sidekiq_ctx[:class],
                transaction_id: sidekiq_ctx[:jid] }
            else
              { transaction_id: rails_transation_id }
            end
          end

          def merge_message(payload, msg)
            if msg.is_a?(Hash)
              payload.merge!(msg.slice(*ALLOWED_PAYLOAD_KEYS))
            else
              payload[:message] = msg2str(msg)
            end
            payload
          end

          private

          def sidekiq_current_ctx
            return unless Module.const_defined?(:Sidekiq)

            if ::Sidekiq.const_defined?(:Context)
              Sidekiq::Context.current
            else
              # versions up to 6.0.0
              parse_sidekiq_ctx(Thread.current[:sidekiq_context])
            end
          rescue NoMethodError
            nil
          end

          def parse_sidekiq_ctx(ctx)
            return unless ctx

            ctx.last.match(/^(?<class>[^\s]+) JID-(?<jid>[^\s]+)/)
          end

          def format_datetime(time)
            time.utc.strftime('%Y-%m-%dT%H:%M:%S.%6NZ')
          end

          def account_number
            Thread.current[:audit_account_number]
          end

          def rails_transation_id
            ActiveSupport::Notifications.instrumenter.id
          end
        end
      end
    end
  end
end
