class DeletePolicies < ActiveRecord::Migration[5.2]
  def up
    drop_table :policies
  end

  def down
    create_table :policies, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
    add_index :policies, :name, unique: true
  end
end
