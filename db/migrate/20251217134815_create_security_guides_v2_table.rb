class CreateSecurityGuidesV2Table < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      SELECT *
      INTO security_guides_v2
      FROM security_guides;
    SQL
  end

  def down
    drop_table :security_guides_v2
  end
end
