class AddReferencesAndIdentifierToRules < ActiveRecord::Migration[7.0]
  def change
    add_column :rules, :references, :jsonb, default: [], index: true
    add_column :rules, :identifier, :jsonb, default: nil, index: true
  end
end
