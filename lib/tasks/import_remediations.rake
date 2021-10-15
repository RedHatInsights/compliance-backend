# frozen_string_literal: true

desc <<-END_DESC
  Update rule remediation availability by querying the Remediations API

  This will update the 'remediation_available' on every rule on the database
  according to whether or not there's a remediation available in the Remediations
  API.

  Examples:
    # JOBS_ACCOUNT_NUMBER=000001 rake import_remediations
END_DESC

# rubocop:disable Metrics/BlockLength
task import_remediations: :environment do
  begin
    start_time = Time.now.utc
    puts "Starting import_remediations job at #{start_time}"

    SsgConfigDownloader.update_ssg_ansible_tasks
    ansible_tasks_revision = YAML.safe_load(
      SsgConfigDownloader.ssg_ansible_tasks
    ).dig('revision')

    if Revision.remediations != ansible_tasks_revision
      playbook_status_by_rule_id = PlaybookDownloader.playbooks_exist?(
        Rule.with_profiles.includes(:benchmark)
      )
      ids_with_playbooks = playbook_status_by_rule_id.filter { |_, v| v }.keys
      ids_sans_playbooks = playbook_status_by_rule_id.filter { |_, v| !v }.keys

      # rubocop:disable Rails/SkipsModelValidations
      Rule.where(id: ids_sans_playbooks)
          .update_all(remediation_available: false)
      Rule.where(id: ids_with_playbooks).update_all(remediation_available: true)
      # rubocop:enable Rails/SkipsModelValidations

      puts "Updated #{ids_with_playbooks.count} rules with remediations"
      puts "Updated #{ids_sans_playbooks.count} rules without remediations"
      Revision.remediations = ansible_tasks_revision
    end

    end_time = Time.now.utc
    duration = end_time - start_time
    puts "Remediations synced to revision: #{Revision.remediations}"
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
# rubocop:enable Metrics/BlockLength
