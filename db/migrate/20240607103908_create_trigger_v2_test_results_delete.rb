class CreateTriggerV2TestResultsDelete < ActiveRecord::Migration[7.1]
  def change
    create_trigger :v2_test_results_delete, on: :v2_test_results
  end
end
