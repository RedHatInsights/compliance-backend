class CreateV1ProfileRulesView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_profile_rules
  end
end
