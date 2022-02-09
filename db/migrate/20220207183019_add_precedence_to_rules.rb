class AddPrecedenceToRules < ActiveRecord::Migration[6.1]
  def change
    add_column :rules, :precedence, :integer
  end
end
