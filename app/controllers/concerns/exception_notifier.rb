# frozen_string_literal: true

# Module to add any info to ExceptionNotifier
module ExceptionNotifier
  extend ActiveSupport::Concern

  included do
    before_action :prepare_exception_notifier
  end

  private

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      current_user: current_user
    }
  end
end

