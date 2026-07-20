# frozen_string_literal: true

logger = Logger.new(STDOUT)
account_count = (ENV['ACCOUNT_COUNT'] || 3).to_i
host_count = (ENV['HOST_COUNT'] || rand(2..4)).to_i

accounts = FactoryBot.create_list(:account, account_count)
logger.info("Generated #{account_count} accounts.")

profiles_by_ref_id = Profile.includes(:security_guide, :os_minor_versions).group_by(&:ref_id)

accounts.each do |account|
  profiles_by_ref_id.each do |_ref_id, profiles|
    next if [true, true, false].sample

    profile = profiles.max_by { |p| p.os_minor_versions.size }
    minor_versions = profile.os_minor_versions.map(&:os_minor_version)
    next if minor_versions.empty?

    policy = Policy.create!(
      account: account,
      profile: profile,
      title: Faker::Lorem.sentence,
      description: Faker::Lorem.paragraph,
      compliance_threshold: rand(50..100)
    )

    minor_versions.sample(rand(1..minor_versions.size)).each do |minor|
      tailoring = begin
        t = Tailoring.for_policy(policy, minor)
        t.save ? t : nil
      rescue Exceptions::OSMinorVersionNotSupported
        nil
      end
      next unless tailoring

      host_count.times do
        FactoryBot.create(
          :test_result,
          :dev_seed,
          account: account,
          report_id: policy.id,
          os_major_version: profile.security_guide.os_major_version.to_i,
          os_minor_version: minor
        )
      end
    end

    logger.info("Created policy '#{policy.title}' for account #{account.org_id}")
  end

  system_count = System.where(org_id: account.org_id).count
  policy_count = account.policies.count
  logger.info("Generated #{system_count} systems and #{policy_count} policies for account #{account.org_id}")
end
