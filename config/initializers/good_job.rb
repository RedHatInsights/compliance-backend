# frozen_string_literal: true

GoodJob.configure do |config|
  config.execution_mode = Rails.env.test? ? :inline : :external
  config.max_threads = ENV.fetch('GOOD_JOB_MAX_THREADS', 5).to_i
  config.shutdown_timeout = 25
  config.preserve_job_records = true
  config.cleanup_preserved_jobs_before_seconds_ago = 14.days.to_i
  config.on_thread_error = ->(exception) { Rails.error.report(exception) }
end
