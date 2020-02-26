# frozen_string_literal: true

# Job deletes test results of a specified profile
class DeleteTestResultsJob
  include Sidekiq::Worker

  def perform(profile_id)
    TestResult.where(profile_id: profile_id).destroy_all
  end
end
