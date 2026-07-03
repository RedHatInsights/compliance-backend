# frozen_string_literal: true

desc 'Remove dangling host associations'
task cleanup_db: :environment do
  start = Time.zone.now

  puts 'Beginning cleanup_db.'

  num_deleted = Account.where.not(
    org_id: System.select(:org_id)
  ).where.not(
    id: Policy.select(:account_id)
  ).delete_all
  puts "Deleted #{num_deleted} Accounts"

  num_deleted = TestResult.where.not(
    system_id: System.select(:id)
  ).delete_all
  puts "Deleted #{num_deleted} TestResults"

  num_deleted = RuleResult.where.not(
    test_result_id: TestResult.select(:id)
  ).delete_all
  puts "Deleted #{num_deleted} RuleResults"

  num_deleted = PolicySystem.where.not(
    system_id: System.select(:id)
  ).delete_all
  puts "Deleted #{num_deleted} PolicySystems"

  puts "Finished cleanup_db in #{Time.zone.now - start} seconds."
end
