class CreateTriggerHistoricalTestResultsDelete < ActiveRecord::Migration[7.1]
  def change
    create_trigger :historical_test_results_delete, on: :historical_test_results
  end
end
