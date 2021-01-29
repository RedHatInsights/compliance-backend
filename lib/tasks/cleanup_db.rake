# frozen_string_literal: true

desc 'Remove dangling host associations'
task cleanup_db: :environment do
  start = Time.zone.now

  puts 'Beginning cleanup_db.'

  num_deleted = Account.where.not(
    account_number: Host.select(:account)
  ).where.not(
    id: Profile.where.not(account_id: nil).select(:account_id)
  ).where.not(
    id: Policy.select(:account_id)
  ).delete_all
  puts "Deleted #{num_deleted} Accounts"

  [TestResult, RuleResult, PolicyHost].map do |model|
    num_deleted = model.where.not(host_id: Host.select(:id)).delete_all

    puts "Deleted #{num_deleted} #{model}s"
  end

  puts "Finished cleanup_db in #{Time.zone.now - start} seconds."
end
