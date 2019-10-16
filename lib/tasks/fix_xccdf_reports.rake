# frozen_string_literal: true

desc <<-END_DESC
  Migrates rules and profiles ref_id field.

  Reports from '-xccdf.xml'-based reports
  (e.g. /usr/share/xml/scap/ssg/content/ssg-rhel8-xccdf.xml)
  were allowed before, but such reports caused ref_ids to be wrong.

  This will update the 'ref_id' field on every rule and profile on the database
  to the standard format when parsing '-ds.xml' based reports. If there is a
  conflict as the account may have had two profiles, one with the correct ref_id
  and another one with the wrong one, it will migrate all results to the correct
  one in the same account.

  Examples:

    # Runs the task for one account
    ACCOUNT_NUMBER=000001 rake fix_xccdf_reports

    # Runs the task for all accounts
    rake fix_xccdf_reports

END_DESC

task fix_xccdf_reports: :environment do
  noop = ENV['NOOP']
  start_time = Time.now.utc
  puts '---------- NOOP --------' if noop
  puts "Starting fix_xccdf_reports job at #{start_time}"

  if ENV['ACCOUNT_NUMBER'].present?
    job = MigrateXCCDFReportsJob.perform_async(ENV['ACCOUNT_NUMBER'], noop)
    puts " - Job #{job} enqueued."
  else
    Account.all.each do |account|
      job = MigrateXCCDFReportsJob.perform_async(account.account_number, noop)
      puts " - Job #{job} enqueued."
    end
  end

  end_time = Time.now.utc
  duration = end_time - start_time
  puts "Finishing fix_xccdf_reports job at #{end_time} "\
       "and last #{duration} seconds"
end
