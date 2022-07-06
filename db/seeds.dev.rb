# frozen_string_literal: true

def create_rule_results(test_results, passing)
  test_results.each do |tr|
    rule_result_columns = tr.profile.rules.pluck(:id).map do |rule_id|
      [rule_id, tr.id, tr.host_id, passing ? 'pass' : %w[pass pass fail].sample]
    end

    RuleResult.import(
      %i[rule_id test_result_id host_id result], rule_result_columns
    )

    tr.update!(score: tr.rule_results.passed.count / tr.rule_results.count.to_f * 100)
  end
end

def create_test_results(profile, host, passing)
  test_result_count = (ENV['TEST_RESULT_COUNT'] || rand(2..3)).to_i

  test_results = FactoryBot.create_list(
    :test_result,
    test_result_count,
    profile: profile,
    host: host,
    supported: SupportedSsg.supported?(
      ssg_version: profile.ssg_version,
      os_major_version: host.os_major_version,
      os_minor_version: host.os_minor_version
    )
  )

  create_rule_results(test_results, passing)
  profile.calculate_score!
end

def find_or_create_profile(policy, canonical_profile, os_minor_version)
  profile = policy.reload.profiles.find_by(os_minor_version: os_minor_version)
  profile || canonical_profile.clone_to(
    policy: policy,
    account: policy.account,
    os_minor_version: os_minor_version.to_s
  )
end

def create_policy(account, canonical_profile, hosts)
  profile = Profile.new(
    parent_profile_id: canonical_profile.id,
    account: account
  ).fill_from_parent

  policy = Policy.new(
    profile.slice(:name, :description, :compliance_threshold, :account)
  )

  policy.save!
  profile.update!(policy: policy)
  policy.update_hosts(hosts.pluck(:id))

  policy
end

logger = Logger.new(STDOUT)
account_count = (ENV['ACCOUNT_COUNT'] || 3).to_i

FactoryBot.create_list(:account, account_count)
logger.info("Generated #{account_count} accounts.")

Account.find_each do |account|
  host_count = (ENV['HOST_COUNT'] || rand(2..3)).to_i

  host_ids = SupportedSsg.all.map { |ssg| [ssg.os_major_version, ssg.os_minor_version] }.uniq.flat_map do |version|
    FactoryBot.create_list(
      :host,
      host_count,
      account: account.account_number,
      os_version_arr: version
    ).map(&:id)
  end

  logger.info("Generated #{host_ids.count} hosts for acc #{account.account_number}")

  Profile.canonical.includes(:benchmark).group_by(&:ref_id).each do |_, profiles|
    canonical_profile = profiles.sample
    supported_minor_versions = canonical_profile.supported_os_versions.map { |sv| sv.version[/[^.]+$/] }
    hosts = Host.where(id: host_ids)
                .where("#{Host::OS_MAJOR_VERSION} = ? AND #{Host::OS_MINOR_VERSION} IN (?)",
                       canonical_profile.os_major_version, supported_minor_versions)

    next if hosts.empty? || [true, true, false].sample

    policy = create_policy(account, canonical_profile, hosts)

    passing_hosts_count = (ENV['PASSING_HOST_COUNT'] || rand(1..policy.hosts.count / 2)).to_i

    passing_hosts = policy.hosts.sample(passing_hosts_count)

    hosts.find_each do |host|
      next if [true, true, false].sample

      profile = find_or_create_profile(
        policy,
        canonical_profile,
        host.os_minor_version
      )

      passing = passing_hosts.include?(host)
      create_test_results(profile, host, passing)
    end
  end

  logger.info("Generated #{account.policies.count} policies for account #{account.account_number}")
end
