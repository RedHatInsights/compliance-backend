class CreateV1TestResultsView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_test_results
  end
end
