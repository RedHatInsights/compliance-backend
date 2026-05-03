class CreateV1TestResultsFunctionsAndTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :v1_test_results_insert
    create_function :v1_test_results_delete
    create_trigger :v1_test_results_insert, on: :v1_test_results
    create_trigger :v1_test_results_delete, on: :v1_test_results
  end
end
