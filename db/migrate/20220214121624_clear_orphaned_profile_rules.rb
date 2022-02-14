class ClearOrphanedProfileRules < ActiveRecord::Migration[6.1]
  def up
    OrphanedLinksRemover.run!
  end

  def down
    # nop
  end
end
