# frozen_string_literal: true

# Removes accounts with NIL account_number
class DeleteNilAccount < ActiveRecord::Migration[5.2]
  def up
    Account.where(account_number: [nil, '']).delete_all
    change_column :accounts, :account_number, :string, null: false
  end

  def down
    change_column :accounts, :account_number, :string, null: true
  end
end
