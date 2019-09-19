class AddRemediationAvailableToRules < ActiveRecord::Migration[5.2]
  def change
    add_column :rules, :remediation_available, :boolean,
      null: false, default: false
  end
end
