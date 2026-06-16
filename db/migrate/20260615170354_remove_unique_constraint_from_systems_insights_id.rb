class RemoveUniqueConstraintFromSystemsInsightsId < ActiveRecord::Migration[8.1]
  def change
    remove_index :systems, :insights_id, unique: true
    add_index :systems, :insights_id
  end
end
