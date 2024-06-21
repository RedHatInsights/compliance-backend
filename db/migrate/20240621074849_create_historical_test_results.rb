class CreateHistoricalTestResults < ActiveRecord::Migration[7.1]
  def change
    create_view :historical_test_results
  end
end
