require 'active_job/logging'

class ActiveJob::Logging::LogSubscriber
  private def args_info(job)
    if ParseReportJob == job.class.name && job.arguments.any?
      return "for account: #{format(arguments[1]).inspect}"
    end
    super(job)
  end
end
