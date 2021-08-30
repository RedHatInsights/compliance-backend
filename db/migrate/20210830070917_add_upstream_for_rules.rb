class AddUpstreamForRules < ActiveRecord::Migration[5.2]
  def change
    add_column :rules, :upstream, :boolean, null: false, default: true
    add_index :rules, :upstream
  end
end
