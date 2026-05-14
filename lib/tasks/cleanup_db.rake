# frozen_string_literal: true

desc 'Remove dangling host associations'
task cleanup_db: :environment do
  start = Time.zone.now

  puts 'Beginning cleanup_db.'

  num_deleted = Account.where.not(
    org_id: V2::System.select(:org_id)
  ).where.not(
    id: V2::Policy.select(:account_id)
  ).delete_all
  puts "Deleted #{num_deleted} Accounts"

  num_deleted = V2::TestResult.where.not(
    system_id: V2::System.select(:id)
  ).delete_all
  puts "Deleted #{num_deleted} V2::TestResults"

  num_deleted = V2::RuleResult.where.not(
    test_result_id: V2::TestResult.select(:id)
  ).delete_all
  puts "Deleted #{num_deleted} V2::RuleResults"

  num_deleted = V2::PolicySystem.where.not(
    system_id: V2::System.select(:id)
  ).delete_all
  puts "Deleted #{num_deleted} V2::PolicySystems"

  puts "Finished cleanup_db in #{Time.zone.now - start} seconds."
end
