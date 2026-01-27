class CreateV1RulesView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_rules
  end
end
