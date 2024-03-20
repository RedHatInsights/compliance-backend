class TailoringRuleView < ActiveRecord::Migration[7.0]
  def change
    create_view :tailoring_rules
  end
end
