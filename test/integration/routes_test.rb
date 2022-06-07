# frozen_string_literal: true

require 'test_helper'

class RoutesTest < ActionController::TestCase
  controllers = Rails.application
                     .routes.routes
                     .map { |route| route.defaults[:controller] }
                     .grep(%r{^v1/(?!statuses)}) # filter out undesired endpoints
                     .uniq
                     .map { |controller| "#{controller}_controller".classify.constantize }

  controllers.each do |controller|
    context "controller #{controller}" do
      controller.instance_methods(false).each do |action|
        should "have RBAC enforcement for '#{action}' action" do
          assert_not controller.instance_variable_get(:@action_permissions)[action].empty?
        end
      end
    end
  end
end
