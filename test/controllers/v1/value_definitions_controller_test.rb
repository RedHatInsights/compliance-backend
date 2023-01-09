# frozen_string_literal: true

require 'test_helper'

module V1
  class ValueDefinitionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      User.current = FactoryBot.create(:user)

      ValueDefinitionsController.any_instance.stubs(:authenticate_user).yields

      @vd1 = FactoryBot.create(:value_definition, title: 'test1')
      @vd2 = FactoryBot.create(:value_definition, title: 'test2')
    end

    test 'list all value_definitions' do
      get v1_value_definitions_url

      assert_response :success

      value_definitions = response.parsed_body

      assert_equal 2, value_definitions['data'].count
      assert_equal(%w[test1 test2], value_definitions['data'].map do |value_definition|
        value_definition['attributes']['title']
      end.sort)
    end

    test 'search by ref_id' do
      get v1_value_definitions_url, params: {
        search: "ref_id=#{@vd1.ref_id}"
      }

      assert_response :success

      value_definitions = response.parsed_body

      assert_equal 1, value_definitions['data'].count
      assert_equal(['test1'], value_definitions['data'].map do |value_definition|
        value_definition['attributes']['title']
      end)
    end

    test 'search by benchmark_id' do
      get v1_value_definitions_url, params: {
        search: "benchmark_id=#{@vd2.benchmark_id}"
      }

      assert_response :success

      value_definitions = response.parsed_body

      assert_equal 1, value_definitions['data'].count
      assert_equal(['test2'], value_definitions['data'].map do |value_definition|
        value_definition['attributes']['title']
      end)
    end
  end
end
