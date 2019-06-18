class CreateBusinessObjectives < ActiveRecord::Migration[5.2]
  def change
    create_table :business_objectives, id: :uuid do |t|
      t.string :title
      t.timestamps
    end

    add_column :profiles, :business_objective_id, :uuid
    add_index :profiles, :business_objective_id
  end
end
