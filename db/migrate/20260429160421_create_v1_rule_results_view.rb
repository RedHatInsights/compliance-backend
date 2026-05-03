class CreateV1RuleResultsView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_rule_results
  end
end
