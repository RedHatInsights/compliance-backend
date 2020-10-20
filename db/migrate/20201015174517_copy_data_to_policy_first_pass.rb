class CopyDataToPolicyFirstPass < ActiveRecord::Migration[5.2]
  def up
    CopyProfilesToPolicies.run!
  end

  def down; end
end
