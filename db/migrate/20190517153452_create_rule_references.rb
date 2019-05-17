class CreateRuleReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :rule_references, id: :uuid do |t|
      t.string :href
      t.string :label
    end
  end
end
