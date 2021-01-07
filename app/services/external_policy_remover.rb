# frozen_string_literal: true

# A service class to remove external policies (i.e. profiles with no policy)
class ExternalPolicyRemover
  class << self
    def run!
      count = Profile.external(true).where(policy_id: nil).destroy_all.count

      Logger.new(STDOUT).info "Removed #{count} external policies"
    end
  end
end
