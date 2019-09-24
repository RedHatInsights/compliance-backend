class CreateBenchmarks < ActiveRecord::Migration[5.2]
  def change
    create_table :benchmarks, id: :uuid do |t|
      t.string :ref_id, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :version, null: false

      t.timestamps
    end
  end
end
