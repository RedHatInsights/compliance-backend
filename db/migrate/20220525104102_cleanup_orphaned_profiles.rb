class CleanupOrphanedProfiles < ActiveRecord::Migration[7.0]
  def up
    OrphanedProfilesCleaner.run!
  end

  def down
    # nop
  end
end
