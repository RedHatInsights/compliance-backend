class DeduplicateBusinessObjectives < ActiveRecord::Migration[6.1]
  def up
    DuplicateBusinessObjectiveResolver.run!
  end

  def down
    # NOP
  end
end
