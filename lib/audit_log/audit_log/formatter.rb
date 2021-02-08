# frozen_string_literal: true

require 'manageiq/loggers'

# Common space for Insights API stuff
module Insights
  module API
    module Common
      class AuditLog
        # Audit Log formatter with evidence capture
        class Formatter < ManageIQ::Loggers::Container::Formatter
          ALLOWED_PAYLOAD_KEYS = %i[message account_number controller remote_ip
                                    transaction_id].freeze

          def call(severity, time, progname, msg)
            payload = {
              '@timestamp': format_datetime(time),
              hostname: hostname,
              pid: $PROCESS_ID,
              thread_id: thread_id,
              service: progname,
              level: translate_error(severity),
              account_number: account_number
            }
            JSON.generate(merge_message(payload, msg).compact) << "\n"
          end

          def merge_message(payload, msg)
            if msg.is_a?(Hash)
              payload.merge!(msg.slice(*ALLOWED_PAYLOAD_KEYS))
            else
              payload[:message] = msg2str(msg)
            end
            if payload[:transaction_id].blank?
              payload[:transaction_id] = transaction_id
            end
            payload
          end

          private

          def format_datetime(time)
            time.utc.strftime('%Y-%m-%dT%H:%M:%S.%6NZ')
          end

          def account_number
            Thread.current[:audit_account_number]
          end

          def transaction_id
            ActiveSupport::Notifications.instrumenter.id
          end
        end
      end
    end
  end
end
