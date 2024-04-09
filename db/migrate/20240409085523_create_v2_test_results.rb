class CreateV2TestResults < ActiveRecord::Migration[7.1]
  def change
    create_view :v2_test_results
  end
end
