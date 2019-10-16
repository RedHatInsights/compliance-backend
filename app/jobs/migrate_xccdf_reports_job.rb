# frozen_string_literal: true

# Migrates ref IDs from reports to comply with the expected standard.
# Profile ref IDs should look like "xccdf_org.ssgproject.content_profile_*"
# Rule ref IDs should look like "xccdf_org.ssgproject.content_rule_*"
class MigrateXCCDFReportsJob
  include Sidekiq::Worker

  def perform(account_number, noop)
    XCCDFReportMigration.new(
      Account.find_by!(account_number: account_number),
      noop
    ).run
  end
end
