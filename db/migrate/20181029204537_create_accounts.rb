# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :account_id
      t.string :account_number
      t.boolean :internal
      t.timestamps
    end

    create_table :users, id: :uuid do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :redhat_id
      t.string :redhat_org_id
      t.string :lang
      t.string :login
      t.string :locale
      t.string :username
      t.boolean :internal
      t.boolean :active
      t.boolean :org_admin
      t.references :account, type: :uuid, index: true
      t.timestamps
    end
  end
end
