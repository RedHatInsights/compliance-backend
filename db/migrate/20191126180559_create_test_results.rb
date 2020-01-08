class CreateTestResults < ActiveRecord::Migration[5.2]
  def change
    create_table :test_results, id: :uuid do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.decimal :score
      t.references :profile, type: :uuid, index: true
      t.references :host, type: :uuid, index: true

      t.timestamps
    end

    add_reference :rule_results, :test_result, type: :uuid, index: true
  end
end
