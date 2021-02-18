# frozen_string_literal: true

# Common space for Insights API stuff
module Insights
  module API
    module Common
      module AuditLog
        # Request events listener, capturing for evidence
        class Middleware
          attr_accessor :logger
          attr_reader :evidence, :request, :status

          def initialize(app)
            @app = app
            @logger = Rails.logger
            @subscribers = []
            @evidence = {}
          end

          def call(env)
            subscribe
            @request = ActionDispatch::Request.new(env)
            @app.call(env).tap do |status, _headers, _body|
              @status = status
              response_finished
            end
          ensure
            unsubscribe
            reset_context
          end

          private

          def response_finished
            payload = {
              controller: evidence[:controller],
              remote_ip: request.remote_ip,
              message: generate_message
            }
            log(payload)
          end

          def generate_message
            status_label = Rack::Utils::HTTP_STATUS_CODES[status]
            parts = [
              "#{request.method} #{request.original_fullpath}" \
              " -> #{status} #{status_label}",
              unpermitted_params_msg,
              halted_cb_msg
            ]
            parts.compact.join('; ')
          end

          def unpermitted_params_msg
            params = evidence[:unpermitted_parameters]
            return if params.blank?

            "unpermitted params #{fmt_params(params)}"
          end

          def halted_cb_msg
            return if evidence[:halted_callback].blank?

            "filter chain halted by :#{evidence[:halted_callback]}"
          end

          def log(payload)
            payload[:status] = status < 400 ? 'success' : 'fail'
            if logger.respond_to?(:audit)
              if status < 400
                logger.audit_success(payload)
              else
                logger.audit_fail(payload)
              end
            else
              # fallback
              logger.info(payload)
            end
          end

          def subscribe
            @subscribers << subscribe_conroller
          end

          # rubocop:disable Metrics/MethodLength
          def subscribe_conroller
            ActiveSupport::Notifications.subscribe(/\.action_controller$/) do
              |name, _started, _finished, _unique_id, payload|
              # https://guides.rubyonrails.org/active_support_instrumentation.html#action-controller
              case name.split('.')[0]
              when 'process_action'
                @evidence[:controller] = fmt_controller(payload)
              when 'halted_callback'
                @evidence[:halted_callback] = payload[:filter]
              when 'unpermitted_parameters'
                @evidence[:unpermitted_parameters] = payload[:keys]
              end
            end
          end
          # rubocop:enable Metrics/MethodLength

          def unsubscribe
            @subscribers.each do |sub|
              ActiveSupport::Notifications.unsubscribe(sub)
            end
            @subscribers.clear
          end

          def reset_context
            AuditLog.audit_with_account(nil)
          end

          def fmt_controller(payload)
            return if payload[:controller].blank?

            [payload[:controller], payload[:action]].compact.join('#')
          end

          def fmt_params(params)
            params.map { |e| ":#{e}" }.join(', ')
          end
        end
      end
    end
  end
end
