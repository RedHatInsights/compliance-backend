# frozen_string_literal: true

require 'test_helper'

module V1
  class BusinessObjectivesControllerTest < ActionDispatch::IntegrationTest
    setup do
      BusinessObjectivesController.any_instance.stubs(:authenticate_user).yields
      User.current = users(:test)
      users(:test).update! account: accounts(:test)
      policies(:one).update!(account: accounts(:test),
                             business_objective: business_objectives(:one))
      policies(:two).update!(account: accounts(:one),
                             business_objective: business_objectives(:two))
    end

    context '#index' do
      should 'only list business objectives associated to owned policies' do
        get v1_business_objectives_path
        assert_response :success
        assert_equal business_objectives(:one).id, parsed_data&.first&.dig('id')
      end
    end

    context '#show' do
      should 'succeed' do
        get v1_business_objective_path(business_objectives(:one))
        assert_response :success
      end

      should 'not show business objectives not associated to owned policies' do
        get v1_business_objective_path(business_objectives(:two))
        assert_response :not_found
      end
    end
  end
end
