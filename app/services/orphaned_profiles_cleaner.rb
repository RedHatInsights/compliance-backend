# frozen_string_literal: true

# Service for cleaning up orphaned profiles
class OrphanedProfilesCleaner
  class << self
    def run!
      Profile.canonical(false).where(policy_id: nil, external: true).destroy_all
    end
  end
end
