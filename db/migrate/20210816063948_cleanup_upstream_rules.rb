class CleanupUpstreamRules < ActiveRecord::Migration[5.2]
  def up
    RulesCleanupService.run!
  end

  def down
    # nop
  end
end
