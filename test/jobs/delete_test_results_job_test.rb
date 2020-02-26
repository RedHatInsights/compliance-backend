# frozen_string_literal: true

require 'test_helper'

class DeleteTestResultsJobTest < ActiveSupport::TestCase
  setup do
    @job = DeleteTestResultsJob.new
    profiles(:one).update(account: accounts(:test))
    test_results(:one).update(profile: profiles(:one), host: hosts(:one))
  end

  test 'it removes test results' do
    assert_difference('TestResult.count', -1) do
      @job.perform(profiles(:one).id)
    end
  end
end
