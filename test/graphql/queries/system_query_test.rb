# frozen_string_literal: true

require 'test_helper'

class SystemQueryTest < ActiveSupport::TestCase
  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    @user = FactoryBot.create(:user)
    @host1 = FactoryBot.create(:host, org_id: @user.account.org_id)

    @profile1, @profile2 = FactoryBot.create_list(
      :profile,
      2,
      :with_rules,
      rule_count: 1,
      account: @user.account
    )

    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  TAG = { 'namespace' => 'foo', 'key' => 'bar', 'value' => 'baz' }.freeze

  test 'query host owned by the user' do
    query = <<-GRAPHQL
      query System($inventoryId: String!){
          system(id: $inventoryId) {
              name
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { inventoryId: @host1.id },
      context: { current_user: @user }
    )

    assert_equal @host1.name, result['data']['system']['name']
  end

  test 'query host owned by another user' do
    query = <<-GRAPHQL
      query System($inventoryId: String!){
          system(id: $inventoryId) {
              name
          }
      }
    GRAPHQL

    @user.update(account: FactoryBot.create(:account))

    assert_raises(Pundit::NotAuthorizedError) do
      Schema.execute(
        query,
        variables: { inventoryId: @host1.id },
        context: { current_user: @user }
      )
    end
  end

  test 'query host returns timestamps in ISO-6801' do
    FactoryBot.create(:test_result, host: @host1, profile: @profile1)

    query = <<-GRAPHQL
      query System($inventoryId: String!){
          system(id: $inventoryId) {
              culledTimestamp
              staleWarningTimestamp
              staleTimestamp
              updated
              lastScanned
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { inventoryId: @host1.id },
      context: { current_user: @user }
    )

    assert_equal 5, result['data']['system'].count
    result['data']['system'].each do |_, timestamp|
      assert_equal timestamp, Time.parse(timestamp).iso8601
    end
  end

  test "query host lastScanned returns 'Never' if no test results" do
    query = <<-GRAPHQL
      query System($inventoryId: String!){
          system(id: $inventoryId) {
              lastScanned
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { inventoryId: @host1.id },
      context: { current_user: @user }
    )

    assert_equal 'Never', result['data']['system']['lastScanned']
  end

  context 'policy id querying' do
    setup do
      [@profile1, @profile2].each do |p|
        p.policy.update(compliance_threshold: 95)
        @host1.policies << p.policy
      end

      # An outdated test result made in the past
      FactoryBot.create(
        :test_result,
        profile: @profile1,
        host: @host1,
        end_time: 1.minute.ago,
        score: 10
      )

      FactoryBot.create(
        :rule_result,
        host: @host1,
        rule: @profile1.rules.first,
        result: 'pass',
        test_result: FactoryBot.create(
          :test_result,
          profile: @profile1,
          host: @host1,
          score: 98
        )
      )

      FactoryBot.create(
        :rule_result,
        host: @host1,
        rule: @profile2.rules.first,
        result: 'fail',
        test_result: FactoryBot.create(
          :test_result,
          profile: @profile2,
          host: @host1,
          supported: false,
          score: 98
        )
      )
    end

    should 'return systems belonging to a policy' do
      query = <<-GRAPHQL
      query getSystems($search: String) {
          systems(limit: 50, offset: 1, search: $search) {
              edges {
                  node {
                      id
                      name
                      testResultProfiles {
                          id
                          rulesPassed
                          rulesFailed
                          lastScanned
                          compliant
                      }
                  }
              }
          }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { search: "policy_id = #{@profile1.id}" },
        context: { current_user: @user }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['testResultProfiles']
      assert_equal 2, result_profiles.length

      passed_profile = result_profiles.find { |p| p['id'] == @profile1.id }
      assert_equal 1, passed_profile['rulesPassed']
      assert_equal 0, passed_profile['rulesFailed']
      assert passed_profile
      assert passed_profile

      failed_profile = result_profiles.find { |p| p['id'] == @profile2.id }
      assert_equal 0, failed_profile['rulesPassed']
      assert_equal 1, failed_profile['rulesFailed']
      assert failed_profile
      assert failed_profile
    end

    should 'return policy profiles using an internal profile id via policyId' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
          systems(limit: 50, offset: 1) {
              edges {
                  node {
                      id
                      name
                      profiles(policyId: $policyId) {
                          id
                          rulesPassed
                          rulesFailed
                          lastScanned
                          compliant
                      }
                  }
              }
          }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { policyId: @profile1.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['profiles']

      assert_equal 1, result_profiles.first['rulesPassed']
      assert_equal 0, result_profiles.first['rulesFailed']
      assert result_profiles.first['lastScanned']
      assert result_profiles.first['compliant']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, @profile1.id
      assert_equal 1, result_profile_ids.length
    end

    should 'search systems based on stale_timestamp' do
      @host2 = FactoryBot.create(
        :host,
        org_id: @host1.org_id,
        stale_timestamp: 2.days.ago(Time.zone.now)
      )
      FactoryBot.create(:policy, account: @user.account, hosts: [Host.find(@host2.id)])

      query = <<-GRAPHQL
      query getSystems($search: String) {
          systems(limit: 50, offset: 1, search: $search) {
              edges {
                  node {
                      id
                      name
                  }
              }
          }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { search: "stale_timestamp<#{Time.zone.now.iso8601}" },
        context: { current_user: @user }
      )['data']['systems']['edges']

      assert_equal result.length, 1
      assert_equal result.first['node']['id'], @host2.id
    end

    should 'filter test result profiles by policyId using an internal' \
           ' profile id' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
          systems(limit: 50, offset: 1) {
              edges {
                  node {
                      id
                      name
                      testResultProfiles(policyId: $policyId) {
                          id
                          rulesPassed
                          rulesFailed
                          lastScanned
                          compliant
                      }
                  }
              }
          }
      }
      GRAPHQL

      (second_benchmark = @profile1.benchmark.dup).update!(version: '1.2.3')
      other_profile = @profile1.dup
      other_profile.update!(policy: @profile1.policy,
                            external: true,
                            benchmark: second_benchmark,
                            account: @user.account)

      @profile1.test_results.map { |tr| tr.update!(profile: other_profile) }

      result = Schema.execute(
        query,
        variables: { policyId: @profile1.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['testResultProfiles']

      assert_equal 1, result_profiles.first['rulesPassed']
      assert_equal 0, result_profiles.first['rulesFailed']
      assert result_profiles.first['lastScanned']
      assert result_profiles.first['compliant']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, other_profile.id
      assert_equal 1, result_profile_ids.length
    end

    should 'return test results filtered by policyId even if the host' \
           ' is not associated to the policy' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
          systems(limit: 50, offset: 1) {
              edges {
                  node {
                      id
                      name
                      testResultProfiles(policyId: $policyId) {
                          id
                          rulesPassed
                          rulesFailed
                          lastScanned
                          compliant
                      }
                  }
              }
          }
      }
      GRAPHQL

      @host1.policies.delete(@profile1.policy)

      result = Schema.execute(
        query,
        variables: { policyId: @profile1.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['testResultProfiles']

      assert_equal 1, result_profiles.first['rulesPassed']
      assert_equal 0, result_profiles.first['rulesFailed']
      assert result_profiles.first['lastScanned']
      assert result_profiles.first['compliant']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, @profile1.id
      assert_equal 1, result_profile_ids.length
    end

    should 'return policy profiles using an any policy profile id' \
           'via policyId' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
          systems(limit: 50, offset: 1) {
              edges {
                  node {
                      id
                      name
                      profiles(policyId: $policyId) {
                          id
                          rulesPassed
                          rulesFailed
                          lastScanned
                          compliant
                      }
                  }
              }
          }
      }
      GRAPHQL

      (second_benchmark = @profile1.benchmark.dup).update!(version: '1.2.3')
      other_profile = @profile1.dup
      other_profile.update!(policy: @profile1.policy,
                            external: true,
                            benchmark: second_benchmark,
                            account: @user.account)

      result = Schema.execute(
        query,
        variables: { policyId: other_profile.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['profiles']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, other_profile.id
      assert_includes result_profile_ids, @profile1.id
      assert_equal 2, result_profile_ids.length
    end

    should 'filter test result profiles by policyId using any policy' \
           ' profile id' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
        systems(limit: 50, offset: 1) {
            edges {
                node {
                    id
                    name
                    testResultProfiles(policyId: $policyId) {
                        id
                        rulesPassed
                        rulesFailed
                        lastScanned
                        compliant
                    }
                }
            }
        }
      }
      GRAPHQL

      (second_benchmark = @profile1.benchmark.dup).update!(version: '1.2.3')
      other_profile = @profile1.dup
      other_profile.update!(policy: @profile1.policy,
                            external: true,
                            benchmark: second_benchmark,
                            account: @user.account)

      result = Schema.execute(
        query,
        variables: { policyId: other_profile.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['testResultProfiles']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, @profile1.id
      assert_equal 1, result_profile_ids.length
    end

    should 'return external profile using an external profile id' \
           ' via policyId' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
          systems(limit: 50, offset: 1) {
              edges {
                  node {
                      id
                      name
                      profiles(policyId: $policyId) {
                          id
                          rulesPassed
                          rulesFailed
                          lastScanned
                          compliant
                      }
                  }
              }
          }
      }
      GRAPHQL

      @profile1.update!(policy_id: nil)

      result = Schema.execute(
        query,
        variables: { policyId: @profile1.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['profiles']

      assert_equal 1, result_profiles.first['rulesPassed']
      assert_equal 0, result_profiles.first['rulesFailed']
      assert result_profiles.first['lastScanned']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, @profile1.id
      assert_equal 1, result_profile_ids.length
    end

    should 'filter polices by policyId using an internal profile id' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
          systems(limit: 50, offset: 1) {
              edges {
                  node {
                      id
                      name
                      policies(policyId: $policyId) {
                          id
                          name
                      }
                  }
              }
          }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { policyId: @profile1.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      returned_policies = result.first['node']['policies']
      assert_equal 1, returned_policies.length

      assert_equal returned_policies.dig(0, 'id'), @profile1.id
      assert_equal returned_policies.dig(0, 'name'), @profile1.policy.name
    end

    should 'return suppotability and SSG information' do
      query = <<-GRAPHQL
      query getSystems($policyId: ID) {
          systems(limit: 50, offset: 1) {
              edges {
                  node {
                      id
                      testResultProfiles(policyId: $policyId) {
                          id
                          rulesPassed
                          rulesFailed
                          lastScanned
                          compliant
                          score
                          supported
                          ssgVersion
                      }
                  }
              }
          }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { policyId: @profile1.id },
        context: { current_user: @user }
      )['data']['systems']['edges']

      returned_profiles = result.dig(0, 'node', 'testResultProfiles')
      assert_equal 1, returned_profiles.length

      assert_equal @profile1.test_results.latest.first.score,
                   returned_profiles.dig(0, 'score')
      assert_equal @profile1.test_results.latest.first.supported,
                   returned_profiles.dig(0, 'supported')
      assert_equal @profile1.ssg_version,
                   returned_profiles.dig(0, 'ssgVersion')
    end
  end

  should 'sort results' do
    query = <<-GRAPHQL
      {
        systems(sortBy: ["osMinorVersion", "name"]) {
          edges {
            node {
              id
              name
            }
          }
        }
      }
    GRAPHQL

    setup_two_hosts
    @host1.update!(display_name: 'b')
    @host2.update!(display_name: 'a', org_id: @user.account.org_id)

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: @user }
    )

    systems = result['data']['systems']['edges']

    assert_equal 'a', systems.first['node']['name']
    assert_equal 'b', systems.second['node']['name']
  end

  should 'return tags when requested' do
    query = <<-GRAPHQL
      {
        systems {
          edges {
            node {
              id
              name
              tags
            }
          }
        }
      }
    GRAPHQL

    WHost.find(@host1.id).update(tags: [TAG])

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: @user }
    )

    node = result['data']['systems']['edges'].first['node']
    assert_equal node['tags'], [TAG]
  end

  should 'allow filtering by tags' do
    query = <<-GRAPHQL
      query getSystems($tags: [String!]){
        systems(tags: $tags) {
          edges {
            node {
              id
              name
            }
          }
        }
      }
    GRAPHQL

    WHost.find(@host1.id).update(
      tags: [{ namespace: 'foo', key: 'bar', value: 'baz' }]
    )
    setup_two_hosts

    result = Schema.execute(
      query,
      variables: {
        tags: ['foo/bar=baz']
      },
      context: { current_user: @user }
    )

    nodes = result['data']['systems']['edges']
    assert_equal(nodes.count, 1)
    assert_equal nodes.first['node']['id'], @host1.id
  end

  test 'query children profile only returns profiles owned by host' do
    query = <<-GRAPHQL
    query getSystems {
        systems {
            edges {
                node {
                    id
                    name
                    profiles {
                        id
                        name
                        rulesPassed
                        rulesFailed
                        lastScanned
                        compliant
                    }
                    testResultProfiles {
                        id
                        name
                        rulesPassed
                        rulesFailed
                        lastScanned
                        compliant
                    }
                }
            }
        }
    }
    GRAPHQL

    setup_two_hosts

    result = Schema.execute(
      query,
      context: { current_user: @user }
    )

    hosts = result['data']['systems']['edges']
    assert_equal 1, hosts.count
    hosts.each do |graphql_host|
      host = Host.find(graphql_host['node']['id'])
      %w[profiles testResultProfiles].each do |field|
        graphql_host['node'][field].each do |graphql_profile|
          assert_includes host.assigned_profiles.map(&:id),
                          graphql_profile['id']
          profile = Profile.find(graphql_profile['id'])
          assert_equal host.rules_passed(profile),
                       graphql_profile['rulesPassed']
          assert_equal host.rules_failed(profile),
                       graphql_profile['rulesFailed']
          assert_includes host.policies.pluck(:name),
                          graphql_profile['name']
        end
      end
    end
  end

  test 'system returns profiles from test results' do
    query = <<-GRAPHQL
    query System($systemId: String!){
        system(id: $systemId) {
            id
            name
            profiles {
                id
                name
            }
            testResultProfiles {
                id
                name
            }
        }
    }
    GRAPHQL

    FactoryBot.create(
      :rule_result,
      host: @host1,
      rule: @profile1.rules.first,
      test_result: FactoryBot.create(
        :test_result,
        host: @host1,
        profile: @profile1
      )
    )

    result = Schema.execute(
      query,
      variables: { systemId: @host1.id },
      context: { current_user: @user }
    )

    returned_profiles = result.dig('data', 'system', 'profiles')
    assert returned_profiles.any?
    assert_includes returned_profiles.map { |p| p['id'] }, @profile1.id

    returned_result_profiles = result.dig('data', 'system',
                                          'testResultProfiles')
    assert returned_result_profiles.any?
    assert_includes returned_result_profiles.map { |p| p['id'] },
                    @profile1.id
  end

  test 'system returns assigned policies' do
    query = <<-GRAPHQL
    query System($systemId: String!){
        system(id: $systemId) {
            id
            name
            policies {
                id
                name
            }
        }
    }
    GRAPHQL

    @host1.policies << @profile1.policy

    result = Schema.execute(
      query,
      variables: { systemId: @host1.id },
      context: { current_user: @user }
    )

    returned_policies = result.dig('data', 'system', 'policies')
    assert_equal 1, returned_policies.length

    assert_equal returned_policies.dig(0, 'id'), @profile1.id
    assert_equal returned_policies.dig(0, 'name'), @profile1.policy.name
  end

  test 'page info can be obtained on system query' do
    query = <<-GRAPHQL
    query getSystems($first: Int) {
        systems(first: $first) {
            totalCount,
            pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
            }
            edges {
                node {
                    id
                    name
                }
            }
        }
    }
    GRAPHQL

    setup_two_hosts
    result = Schema.execute(
      query,
      variables: { first: 1 },
      context: { current_user: @user }
    )['data']

    assert_equal false, result['systems']['pageInfo']['hasPreviousPage']
    assert_equal false, result['systems']['pageInfo']['hasNextPage']
  end

  test 'available OS versions can be obtained on system query' do
    query = <<-GRAPHQL
    query getSystems($first: Int) {
        systems(first: $first) {
            osVersions
        }
    }
    GRAPHQL

    setup_two_hosts
    result = Schema.execute(
      query,
      variables: { first: 1 },
      context: { current_user: @user }
    )['data']

    assert_equal(
      [{ 'name' => 'RHEL', 'major' => 7, 'minor' => 9 }],
      result.dig('systems', 'osVersions')
    )
  end

  test 'available tags can be obtained on system query' do
    query = <<-GRAPHQL
    query getSystems($limit: Int) {
        systems(limit: $limit) {
            tags
        }
    }
    GRAPHQL

    setup_two_hosts

    WHost.update(tags: [TAG])

    result = Schema.execute(
      query,
      variables: { limit: 1 },
      context: { current_user: @user }
    )['data']

    assert_equal_sets(
      [TAG],
      result.dig('systems', 'tags')
    )

    result = Schema.execute(
      query,
      variables: { limit: 1, offset: 2 },
      context: { current_user: @user }
    )['data']

    assert_equal_sets(
      [TAG],
      result.dig('systems', 'tags')
    )
  end

  test 'limit and offset paginate the query' do
    query = <<-GRAPHQL
    query getSystems($perPage: Int, $page: Int) {
        systems(limit: $perPage, offset: $page) {
            totalCount,
            edges {
                node {
                    id
                    name
                }
            }
        }
    }
    GRAPHQL

    setup_two_hosts
    @host2.update!(policies: [@profile1.policy], org_id: @host1.org_id)

    result = Schema.execute(
      query,
      variables: { perPage: 1, page: 1 },
      context: { current_user: @user }
    )['data']

    assert_equal @user.account.hosts.count,
                 result['systems']['totalCount']
    assert_equal 1, result['systems']['edges'].count
  end

  test 'search is applied to results and total count refers to search' do
    query = <<-GRAPHQL
    query getSystems($search: String) {
        systems(search: $search) {
            totalCount
            edges {
                node {
                    id
                    name
                }
            }
        }
    }
    GRAPHQL
    setup_two_hosts
    result = Schema.execute(
      query,
      variables: { search: "policy_id = #{@profile1.id}" },
      context: { current_user: @user }
    )['data']
    graphql_host = Host.find(result['systems']['edges'].first['node']['id'])
    assert_equal 1, result['systems']['totalCount']
    assert graphql_host.assigned_profiles.pluck(:id).include?(@profile1.id)
  end

  test 'search for systems with a specific score for a given profile' do
    # setup_two_hosts
    @host2 = FactoryBot.create(
      :host,
      org_id: @user.account.org_id,
      os_minor_version: 7
    )
    @profile1.policy.update(hosts: [@host1, @host2])

    FactoryBot.create(
      :test_result,
      host: @host1,
      profile: @profile1,
      score: 52
    )
    FactoryBot.create(
      :test_result,
      host: @host2,
      profile: @profile1,
      score: 40
    )

    query = <<-GRAPHQL
      query getSystems($filter: String!, $policyId: ID) {
        systems(search: $filter) {
          totalCount
          edges {
            node {
              id
              name
              testResultProfiles(policyId: $policyId) {
                id
                name
                lastScanned
                compliant
                score
              }
            }
          }
        }
      }
    GRAPHQL

    filter = <<-FILTER
      (with_results_for_policy_id = #{@profile1.id}) and
      (has_test_results = true and compliance_score >= 45 and compliance_score <= 55)
    FILTER

    result = Schema.execute(
      query,
      variables: { filter: filter },
      context: { current_user: @user }
    )

    node = result['data']['systems']['edges'][0]['node']

    assert_equal result['data']['systems']['totalCount'], 1
    assert_equal node['id'], @host1.id
    assert_equal node['testResultProfiles'][0]['score'], 52
  end

  test 'search for systems with specific benchmark versions for a given profile' do
    @profile3 = FactoryBot.create(
      :profile,
      :with_rules,
      rule_count: 1,
      account: @user.account,
      parent_profile: @profile1.parent_profile,
      policy: @profile1.policy
    )

    @profile2.update(parent_profile: @profile1.parent_profile, policy: @profile1.policy)

    @host2 = FactoryBot.create(
      :host,
      org_id: @user.account.org_id,
      os_minor_version: 7
    )

    @host3 = FactoryBot.create(
      :host,
      org_id: @user.account.org_id,
      os_minor_version: 7
    )

    FactoryBot.create(:test_result, host: @host1, profile: @profile1)
    FactoryBot.create(:test_result, host: @host2, profile: @profile2)
    FactoryBot.create(:test_result, host: @host3, profile: @profile3)

    query = <<-GRAPHQL
      query getSystems($filter: String!, $policyId: ID) {
        systems(search: $filter) {
          totalCount
          edges {
            node {
              id
              testResultProfiles(policyId: $policyId) {
                id
              }
            }
          }
        }
      }
    GRAPHQL

    filter = <<-FILTER
      (with_results_for_policy_id = #{@profile1.id}) and
      (has_test_results = true and ssg_version ^ (#{@profile2.benchmark.version}, #{@profile3.benchmark.version}))
    FILTER

    result = Schema.execute(
      query,
      variables: { filter: filter },
      context: { current_user: @user }
    )

    nodes = result['data']['systems']['edges'].map { |e| e['node']['id'] }.sort

    assert_equal result['data']['systems']['totalCount'], 2
    assert_equal nodes, [@host2.id, @host3.id].sort
  end

  test 'search for systems with supported or unsupported profiles' do
    # setup_two_hosts
    @host2 = FactoryBot.create(
      :host,
      org_id: @user.account.org_id,
      os_minor_version: 7
    )
    @profile1.policy.update(hosts: [@host1, @host2])

    FactoryBot.create(
      :test_result,
      host: @host1,
      profile: @profile1,
      supported: false
    )
    FactoryBot.create(
      :test_result,
      host: @host2,
      profile: @profile1
    )

    query = <<-GRAPHQL
      query getSystems($filter: String!, $policyId: ID) {
        systems(search: $filter) {
          totalCount
          edges {
            node {
              id
              name
              testResultProfiles(policyId: $policyId) {
                id
                name
                supported
              }
            }
          }
        }
      }
    GRAPHQL

    filter = <<-FILTER
      (with_results_for_policy_id = #{@profile1.id}) and
      (supported_ssg = false)
    FILTER

    result = Schema.execute(
      query,
      variables: { filter: filter },
      context: { current_user: @user }
    )

    node = result['data']['systems']['edges'][0]['node']

    assert_equal result['data']['systems']['totalCount'], 1
    assert_equal node['id'], @host1.id

    filter = <<-FILTER
      (with_results_for_policy_id = #{@profile1.id}) and
      (supported_ssg = true)
    FILTER

    result = Schema.execute(
      query,
      variables: { filter: filter },
      context: { current_user: @user }
    )

    node = result['data']['systems']['edges'][0]['node']

    assert_equal result['data']['systems']['totalCount'], 1
    assert_equal node['id'], @host2.id
  end

  test 'search for systems with reported or not reported profiles' do
    # setup_two_hosts
    @host2 = FactoryBot.create(
      :host,
      org_id: @user.account.org_id,
      os_minor_version: 7
    )
    @profile1.policy.update(hosts: [@host1, @host2])

    FactoryBot.create(
      :test_result,
      host: @host1,
      profile: @profile1
    )

    query = <<-GRAPHQL
      query getSystems($filter: String!, $policyId: ID) {
        systems(search: $filter) {
          totalCount
          edges {
            node {
              id
              name
              testResultProfiles(policyId: $policyId) {
                id
                name
                lastScanned
                compliant
                score
              }
            }
          }
        }
      }
    GRAPHQL

    filter = <<-FILTER
      (policy_id = #{@profile1.id}) and (reported = true)
    FILTER

    result = Schema.execute(
      query,
      variables: { filter: filter },
      context: { current_user: @user }
    )

    node = result['data']['systems']['edges'][0]['node']

    assert_equal result['data']['systems']['totalCount'], 1
    assert_equal node['id'], @host1.id

    filter = <<-FILTER
      (policy_id = #{@profile1.id}) and (reported = false)
    FILTER

    result = Schema.execute(
      query,
      variables: { filter: filter },
      context: { current_user: @user }
    )

    node = result['data']['systems']['edges'][0]['node']

    assert_equal result['data']['systems']['totalCount'], 1
    assert_equal node['id'], @host2.id
  end

  test 'query system rules when results contain wrong rule_ids' do
    query = <<-GRAPHQL
    query System($systemId: String!){
      system(id: $systemId) {
        profiles {
          id
          name
          totalHostCount
          compliantHostCount
          rules {
            title
            severity
            rationale
            refId
            description
            compliant
            remediationAvailable
            references
            identifier
          }
        }
      }
    }
    GRAPHQL
    @host1.policies << @profile1.policy

    tr = FactoryBot.create(:test_result, profile: @profile1, host: @host1)
    rule1 = @profile1.rules.first
    rule2 = FactoryBot.create(:rule, benchmark: @profile1.rules.first.benchmark)
    @profile1.rules << rule2

    FactoryBot.create(
      :rule_result,
      rule: rule1,
      host: @host1,
      test_result: tr
    )
    FactoryBot.create(
      :rule_result,
      host: @host1,
      test_result: tr,
      rule: rule2
    )

    rule1.delete

    assert_nothing_raised do
      result = Schema.execute(
        query,
        variables: { systemId: @host1.id },
        context: { current_user: @user }
      )
      response_rules = result['data']['system']['profiles'][0]['rules']

      assert_equal 1, response_rules.length
      assert_equal rule2.ref_id, response_rules[0]['refId']
    end
  end

  private

  def setup_two_hosts
    acc = FactoryBot.create(:account)
    @host2 = FactoryBot.create(
      :host,
      policies: [@profile2.policy],
      org_id: acc.org_id
    )

    @host1.update!(policies: [@profile1.policy])
  end

  context 'unauthorized user' do
    setup do
      stub_rbac_permissions
    end

    should 'have the query action rejected' do
      query = <<-GRAPHQL
        query System($inventoryId: String!){
            system(id: $inventoryId) {
                name
            }
        }
      GRAPHQL

      error = assert_raises(GraphQL::UnauthorizedError) do
        Schema.execute(
          query,
          variables: { inventoryId: @host1.id },
          context: { current_user: @user }
        )
      end
      assert_equal error.message, 'User is not authorized to access this action.'
    end
  end
end
