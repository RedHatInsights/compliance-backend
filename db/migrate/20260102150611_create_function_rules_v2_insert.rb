class CreateFunctionRulesV2Insert < ActiveRecord::Migration[8.0]
  def change
    create_function :rules_v2_insert, revert_to_version: 1
  end
end
