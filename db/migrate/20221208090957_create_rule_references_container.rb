class CreateRuleReferencesContainer < ActiveRecord::Migration[7.0]
  def change
    create_table :rule_references_containers, id: :uuid do |t|
      t.references :rule, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.jsonb :rule_references

      t.timestamps
    end
  end
end
