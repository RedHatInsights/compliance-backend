class CreateTriggerV2TestResultsInsert < ActiveRecord::Migration[7.1]
  def change
    create_trigger :v2_test_results_insert, on: :v2_test_results
  end
end
