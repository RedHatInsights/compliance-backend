# frozen_string_literal: true

require 'test_helper'

class SystemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SystemsController.any_instance.expects(:authenticate_user)
  end

  test 'index lists all systems' do
    SystemsController.any_instance.expects(:policy_scope).with(Host)
                     .returns(Host.all).at_least_once
    get systems_url

    assert_response :success
  end

  test 'index accepts search' do
    SystemsController.any_instance.expects(:policy_scope).with(Host)
                     .returns(Host.all).at_least_once
    get systems_url, params: { search: 'name=bar' }

    assert_response :success
  end

  test 'destroy hosts with authorized user' do
    User.current = users(:test)
    users(:test).update(account: accounts(:test))
    hosts(:one).update(account: accounts(:test))
    assert_difference('Host.count', -1) do
      delete "#{systems_url}/#{hosts(:one).id}"
    end
    assert_response :success
  end

  test 'does not destroy hosts that do not belong to the user' do
    User.current = users(:test)
    users(:test).update(account: accounts(:test))
    hosts(:one).update(account: nil)
    assert_difference('Host.count', 0) do
      delete "#{systems_url}/#{hosts(:one).id}"
    end
    assert_response :forbidden
  end

  context 'csv' do
    setup do
      User.current = users(:test)
    end

    should 'include default fields without columns parameter' do
      get "#{systems_url}.csv?search=name=#{hosts(:one).name}"
      csv_response = CSV.parse(@response.body)
      assert_equal(
        ['Name', 'Profile Names', 'Rules Failed', 'Compliance Score',
         'Last Scanned'],
        csv_response[0]
      )
      expected_response = [
        hosts(:one).name, hosts(:one).profile_names,
        hosts(:one).rules_failed.to_s,
        hosts(:one).compliance_score, hosts(:one).last_scanned
      ]
      assert_equal expected_response, csv_response[1]
    end

    should 'include specific fields from columns parameter' do
      get "#{systems_url}.csv?search=name=#{hosts(:one).name}&"\
        'columns=rules_passed,compliance_score'
      csv_response = CSV.parse(@response.body)
      assert_equal(['Rules Passed', 'Compliance Score'], csv_response[0])
      expected_response = [
        hosts(:one).rules_passed.to_s, hosts(:one).compliance_score
      ]
      assert_equal expected_response, csv_response[1]
    end

    should 'translate certain column params to the right attributes' do
      get "#{systems_url}.csv?search=name=#{hosts(:one).name}&"\
        'columns=profile,profiles,compliant'
      csv_response = CSV.parse(@response.body)
      assert_equal(['Profile Names', 'Profile Names', 'Compliance Score'],
                   csv_response[0])
      expected_response = [
        hosts(:one).profile_names, hosts(:one).profile_names,
        hosts(:one).compliance_score
      ]
      assert_equal expected_response, csv_response[1]
    end
  end
end
