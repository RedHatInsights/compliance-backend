# frozen_string_literal: true

# Service for removing upstream profiles
class UpstreamProfileRemover
  class << self
    def run!
      Profile.canonical(false)
             .joins(:parent_profile)
             .joins(:test_results)
             .where(parent_profiles_profiles: { upstream: true })
             .distinct.destroy_all
    end
  end
end
