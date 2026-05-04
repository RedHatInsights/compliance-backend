class CreateV1RuleReferencesContainersView < ActiveRecord::Migration[8.1]
  def change
    create_view :v1_rule_references_containers
  end
end
