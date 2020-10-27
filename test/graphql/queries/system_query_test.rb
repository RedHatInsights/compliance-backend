# frozen_string_literal: true

require 'test_helper'

class SystemQueryTest < ActiveSupport::TestCase
  setup do
    profiles(:one).update! policy_object: policies(:one),
                           account: accounts(:test)
    profiles(:two).update! policy_object: policies(:two),
                           account: accounts(:test)
    users(:test).update account: accounts(:test)
    hosts(:one).update account: accounts(:test)
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

    hosts(:one).update account: accounts(:test)
    users(:test).update account: nil

    assert_raises(Pundit::NotAuthorizedError) do
      Schema.execute(
        query,
        variables: { inventoryId: hosts(:one).id },
        context: { current_user: users(:test) }
      )
    end
  end

  test 'query attributes with profileId arguments' do
    query = <<-GRAPHQL
    query getSystems($search: String) {
        systems(limit: 50, offset: 1, search: $search) {
            edges {
                node {
                    id
                    name
                    profiles {
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

    rule_results(:one).update(
      host: hosts(:one), rule: rules(:one), test_result: test_results(:one)
    )
    rule_results(:two).update(
      host: hosts(:one), rule: rules(:two), test_result: test_results(:two)
    )
    test_results(:one).update(profile: profiles(:one), host: hosts(:one))
    test_results(:two).update(profile: profiles(:two), host: hosts(:one))
    profiles(:one).rules << rules(:one)
    profiles(:two).rules << rules(:two)
    policies(:one).update(compliance_threshold: 95)
    policies(:two).update(compliance_threshold: 95)
    hosts(:one).policies << policies(:one)
    hosts(:one).policies << policies(:two)

    result = Schema.execute(
      query,
      variables: { search: "profile_id = #{profiles(:one).id}" },
      context: { current_user: users(:test) }
    )['data']['systems']['edges']

    result_profiles = result.first['node']['profiles']

    assert_equal 1, result_profiles.first['rulesPassed']
    assert_equal 0, result_profiles.first['rulesFailed']
    assert result_profiles.first['lastScanned']
    assert result_profiles.first['compliant']
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
    assert_equal 2, hosts.count
    hosts.each do |graphql_host|
      host = Host.find(graphql_host['node']['id'])
      graphql_host['node']['profiles'].each do |graphql_profile|
        assert host.profiles.map(&:name).include? graphql_profile['name']
        profile = Profile.find(graphql_profile['id'])
        assert_equal host.rules_passed(profile), graphql_profile['rulesPassed']
        assert_equal host.rules_failed(profile), graphql_profile['rulesFailed']
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
        }
    }
    GRAPHQL

    profiles(:one).update!(policy_object: nil)
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
    assert_equal true, result['systems']['pageInfo']['hasNextPage']
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
      variables: { search: "profile_id = #{profiles(:one).id}" },
      context: { current_user: users(:test) }
    )['data']
    graphql_host = Host.find(result['systems']['edges'].first['node']['id'])
    assert_not_equal users(:test).account.hosts.count,
                     result['systems']['totalCount']
    assert_equal 1, result['systems']['totalCount']
    assert graphql_host.profiles.pluck(:id).include?(profiles(:one).id)
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
    hosts(:two).update(account: accounts(:test))
  end
  # rubocop:enable AbcSize
end
