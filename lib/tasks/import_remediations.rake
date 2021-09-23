# frozen_string_literal: true

desc <<-END_DESC
  Update rule remediation availability by querying the Remediations API

  This will update the 'remediation_available' on every rule on the database
  according to whether or not there's a remediation available in the Remediations
  API.

  Examples:
    # JOBS_ACCOUNT_NUMBER=000001 rake import_remediations
END_DESC

task import_remediations: :environment do
  begin
    start_time = Time.now.utc
    puts "Starting import_remediations job at #{start_time}"
    RemediationsAPI.new(
      Account.new(account_number: ENV['JOBS_ACCOUNT_NUMBER'])
    ).import_remediations
    end_time = Time.now.utc
    duration = end_time - start_time
    puts "Finishing import_remediations job at #{end_time} "\
         "and last #{duration} seconds "
  rescue StandardError => e
    puts "import_remediations job failed at #{end_time} "\
         "and lasted #{duration} seconds "
    ExceptionNotifier.notify_exception(
      e,
      data: OpenshiftEnvironment.summary
    )
    raise
  end
end
