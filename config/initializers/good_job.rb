# frozen_string_literal: true

Rails.application.configure do
  config.good_job.execution_mode = :external
  config.good_job.max_threads = ENV.fetch('GOOD_JOB_MAX_THREADS', 5).to_i
  config.good_job.shutdown_timeout = 25
  config.good_job.preserve_job_records = lambda { |_job, _error, error_event|
    error_event == :unhandled
  }
  config.good_job.cleanup_preserved_jobs_before_seconds_ago = 14.days.to_i
  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception) }
end
