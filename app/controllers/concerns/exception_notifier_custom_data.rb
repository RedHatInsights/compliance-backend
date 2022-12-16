# frozen_string_literal: true

# Module to add any info to ExceptionNotifier
module ExceptionNotifierCustomData
  extend ActiveSupport::Concern

  included do
    prepend_before_action :prepare_exception_notifier
    before_action :extend_exception_notifier
  end

  private

  def prepare_exception_notifier
    request.env['exception_notifier.exception_data'] = OpenshiftEnvironment.summary
  end

  def extend_exception_notifier
    request.env['exception_notifier.exception_data'].merge!(
      current_user: current_user&.account&.org_id,
      gql_op: respond_to?(:parse_gql_op, true) ? parse_gql_op : nil
    )
  end
end
