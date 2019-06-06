class CreateRuleIdentifierTable < ActiveRecord::Migration[5.2]
  def change
    create_table :rule_identifiers, id: :uuid do |t|
      t.string :label
      t.string :system
      t.references :rule, type: :uuid
    end
  end
end
