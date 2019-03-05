require 'active_job/logging'

class ActiveJob::Logging::LogSubscriber
  private def args_info(job)
    if 'ParseReportJob' == job.class.name && job.arguments.any?
      return " for account: #{format(job.arguments[1]).inspect}"
    else
      " with arguments: " +
        job.arguments.map { |arg| format(arg).inspect }.join(", ")
    end
  end
end
