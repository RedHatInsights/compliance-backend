# frozen_string_literal: true

require 'test_helper'

class SystemQueryTest < ActiveSupport::TestCase
  setup do
    profiles(:one).update! policy: policies(:one),
                           account: accounts(:one)
    profiles(:two).update! policy: policies(:two),
                           account: accounts(:one)
    users(:test).update account: accounts(:one)
  end

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
      variables: { inventoryId: hosts(:one).id },
      context: { current_user: users(:test) }
    )

    assert_equal hosts(:one).name, result['data']['system']['name']
  end

  test 'query host owned by another user' do
    query = <<-GRAPHQL
      query System($inventoryId: String!){
          system(id: $inventoryId) {
              name
          }
      }
    GRAPHQL

    users(:test).update account: accounts(:two)

    assert_raises(Pundit::NotAuthorizedError) do
      Schema.execute(
        query,
        variables: { inventoryId: hosts(:one).id },
        context: { current_user: users(:test) }
      )
    end
  end

  context 'policy id querying' do
    setup do
      rule_results(:one).update(
        host: hosts(:one), rule: rules(:one), test_result: test_results(:one)
      )
      rule_results(:two).update(
        host: hosts(:one), rule: rules(:two), test_result: test_results(:two)
      )
      test_results(:one).update(profile: profiles(:one), host: hosts(:one))
      test_results(:two).update(profile: profiles(:two), host: hosts(:one),
                                supported: false)
      profiles(:one).rules << rules(:one)
      profiles(:two).rules << rules(:two)
      policies(:one).update(compliance_threshold: 95)
      policies(:two).update(compliance_threshold: 95)
      hosts(:one).policies << policies(:one)
      hosts(:one).policies << policies(:two)
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
        variables: { search: "policy_id = #{profiles(:one).id}" },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['testResultProfiles']
      assert_equal 2, result_profiles.length

      passed_profile = result_profiles.find { |p| p['id'] == profiles(:one).id }
      assert_equal 1, passed_profile['rulesPassed']
      assert_equal 0, passed_profile['rulesFailed']
      assert passed_profile
      assert passed_profile

      failed_profile = result_profiles.find { |p| p['id'] == profiles(:two).id }
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
        variables: { policyId: profiles(:one).id },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['profiles']

      assert_equal 1, result_profiles.first['rulesPassed']
      assert_equal 0, result_profiles.first['rulesFailed']
      assert result_profiles.first['lastScanned']
      assert result_profiles.first['compliant']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, profiles(:one).id
      assert_equal 1, result_profile_ids.length
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

      (second_benchmark = benchmarks(:one).dup).update!(version: '1.2.3')
      other_profile = profiles(:one).dup
      other_profile.update!(policy: policies(:one),
                            external: true,
                            benchmark: second_benchmark,
                            account: accounts(:test))

      test_results(:one).update!(profile: other_profile)

      result = Schema.execute(
        query,
        variables: { policyId: profiles(:one).id },
        context: { current_user: users(:test) }
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

      hosts(:one).policies.delete(policies(:one))

      result = Schema.execute(
        query,
        variables: { policyId: profiles(:one).id },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['testResultProfiles']

      assert_equal 1, result_profiles.first['rulesPassed']
      assert_equal 0, result_profiles.first['rulesFailed']
      assert result_profiles.first['lastScanned']
      assert result_profiles.first['compliant']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, profiles(:one).id
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

      (second_benchmark = benchmarks(:one).dup).update!(version: '1.2.3')
      other_profile = profiles(:one).dup
      other_profile.update!(policy: policies(:one),
                            external: true,
                            benchmark: second_benchmark,
                            account: accounts(:test))

      result = Schema.execute(
        query,
        variables: { policyId: other_profile.id },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['profiles']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, other_profile.id
      assert_includes result_profile_ids, profiles(:one).id
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

      (second_benchmark = benchmarks(:one).dup).update!(version: '1.2.3')
      other_profile = profiles(:one).dup
      other_profile.update!(policy: policies(:one),
                            external: true,
                            benchmark: second_benchmark,
                            account: accounts(:test))

      result = Schema.execute(
        query,
        variables: { policyId: other_profile.id },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['testResultProfiles']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, profiles(:one).id
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

      profiles(:one).update!(policy_id: nil)

      result = Schema.execute(
        query,
        variables: { policyId: profiles(:one).id },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      result_profiles = result.first['node']['profiles']

      assert_equal 1, result_profiles.first['rulesPassed']
      assert_equal 0, result_profiles.first['rulesFailed']
      assert result_profiles.first['lastScanned']

      result_profile_ids = result_profiles.map { |p| p['id'] }
      assert_includes result_profile_ids, profiles(:one).id
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
        variables: { policyId: profiles(:one).id },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      returned_policies = result.first['node']['policies']
      assert_equal 1, returned_policies.length

      assert_equal returned_policies.dig(0, 'id'), profiles(:one).id
      assert_equal returned_policies.dig(0, 'name'), policies(:one).name
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
        variables: { policyId: profiles(:one).id },
        context: { current_user: users(:test) }
      )['data']['systems']['edges']

      returned_profiles = result.dig(0, 'node', 'testResultProfiles')
      assert_equal 1, returned_profiles.length

      assert_equal test_results(:one).score, returned_profiles.dig(0, 'score')
      assert_equal test_results(:one).supported,
                   returned_profiles.dig(0, 'supported')
      assert_equal profiles(:one).ssg_version,
                   returned_profiles.dig(0, 'ssgVersion')
    end
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
      context: { current_user: users(:test) }
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

    profiles(:one).rules << rules(:one)
    rule_results(:one).update(
      host: hosts(:one), rule: rules(:one), test_result: test_results(:one)
    )
    test_results(:one).update(profile: profiles(:one), host: hosts(:one))

    result = Schema.execute(
      query,
      variables: { systemId: hosts(:one).id },
      context: { current_user: users(:test) }
    )

    returned_profiles = result.dig('data', 'system', 'profiles')
    assert returned_profiles.any?
    assert_includes returned_profiles.map { |p| p['id'] }, profiles(:one).id

    returned_result_profiles = result.dig('data', 'system',
                                          'testResultProfiles')
    assert returned_result_profiles.any?
    assert_includes returned_result_profiles.map { |p| p['id'] },
                    profiles(:one).id
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

    hosts(:one).policies << policies(:one)

    result = Schema.execute(
      query,
      variables: { systemId: hosts(:one).id },
      context: { current_user: users(:test) }
    )

    returned_policies = result.dig('data', 'system', 'policies')
    assert_equal 1, returned_policies.length

    assert_equal returned_policies.dig(0, 'id'), profiles(:one).id
    assert_equal returned_policies.dig(0, 'name'), policies(:one).name
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
      context: { current_user: users(:test) }
    )['data']

    assert_equal false, result['systems']['pageInfo']['hasPreviousPage']
    assert_equal false, result['systems']['pageInfo']['hasNextPage']
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
    result = Schema.execute(
      query,
      variables: { perPage: 1, page: 1 },
      context: { current_user: users(:test) }
    )['data']

    assert_equal users(:test).account.hosts.count,
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
      variables: { search: "policy_id = #{profiles(:one).id}" },
      context: { current_user: users(:test) }
    )['data']
    graphql_host = Host.find(result['systems']['edges'].first['node']['id'])
    assert_equal 1, result['systems']['totalCount']
    assert graphql_host.assigned_profiles.pluck(:id).include?(profiles(:one).id)
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
    hosts(:one).policies << policies(:one)
    test_results(:one).update(profile: profiles(:one), host: hosts(:one))
    rule_results(:one).update(
      host: hosts(:one), rule: rules(:one), test_result: test_results(:one)
    )
    rule_results(:two).update(
      host: hosts(:one), rule: rules(:two), test_result: test_results(:one)
    )
    rules(:one).delete

    assert_nothing_raised do
      result = Schema.execute(
        query,
        variables: { systemId: hosts(:one).id },
        context: { current_user: users(:test) }
      )
      response_rules = result['data']['system']['profiles'][0]['rules']

      assert_equal 1, response_rules.length
      assert_equal rules(:two).ref_id, response_rules[0]['refId']
    end
  end

  private

  # rubocop:disable AbcSize
  def setup_two_hosts
    hosts(:one).policies << policies(:one)
    hosts(:two).policies << policies(:two)
    profiles(:one).rules << rules(:one)
    profiles(:two).rules << rules(:two)
  end
  # rubocop:enable AbcSize
end
