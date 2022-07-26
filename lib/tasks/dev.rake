# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :dev do
  task 'db:seed': [:environment, 'ssg:check_synced'] do
    load(Rails.root.join('db/seeds.dev.rb'))
  end

  namespace :gabi do
    namespace :seed do
      task :canonicals, %i[token url] => [:environment] do |_t, args|
        require 'gabi'

        gabi = Gabi.new(url: args[:url] || ENV['GABI_URL'], token: args[:token] || ENV['GABI_TOKEN'])

        gabi.seed(Xccdf::Benchmark.all)
        gabi.seed(Profile.canonical)
        gabi.seed(Rule.all)
        gabi.seed(ProfileRule.joins(:profile).where(profiles: { parent_profile_id: nil }))
        # gabi.seed(RuleReference.all.unscoped)
        # gabi.seed(RuleReferencesRule.all)
        # gabi.seed(RuleIdentifier.all)
        gabi.seed(Revision.all)
      end

      task :inventory, %i[account token url] => [:environment] do |_t, args|
        require 'gabi'

        gabi = Gabi.new(url: args[:url] || ENV['GABI_URL'], token: args[:token] || ENV['GABI_TOKEN'])

        hosts = Host.with_policies_or_test_results
        hosts = hosts.where(account: args[:account]) if args[:account]

        gabi.raw_seed(WHost, hosts.to_sql) do |colname, value|
          case colname
          when 'created'
            ['created_on', value]
          when 'updated'
            ['modified_on', value]
          when 'system_profile'
            ['system_profile_facts', JSON.parse(value)]
          when 'tags'
            ['tags', JSON.parse(value)]
          when 'insights_id'
            ['canonical_facts', { insighs_id: value }]
          when 'stale_warning_timestamp', 'culled_timestamp'
            nil
          else
            [colname, value]
          end
        end
      end

      task :userdata, %i[account token url] => [:environment] do |_t, args|
        require 'gabi'

        gabi = Gabi.new(url: args[:url] || ENV['GABI_URL'], token: args[:token] || ENV['GABI_TOKEN'])

        accounts = args[:account] ? Account.where(account_number: args[:account]) : Account.all
        profiles = Profile.where(account: accounts)
        test_results = TestResult.where(profile: profiles)
        policies = Policy.where(account: accounts)

        gabi.seed(accounts)
        gabi.seed(BusinessObjective.joins(:policies).where(policies: policies))
        gabi.seed(policies)
        gabi.seed(profiles)
        gabi.seed(ProfileRule.where(profile: profiles))
        gabi.seed(TestResult.where(profile: profiles))
        gabi.seed(RuleResult.where(test_result: test_results))
        # gabi.seed(PolicyHost.where(policy: policies))
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
