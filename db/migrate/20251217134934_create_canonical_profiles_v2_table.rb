class CreateCanonicalProfilesV2Table < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      SELECT *
      INTO canonical_profiles_v2
      FROM canonical_profiles;
    SQL
  end

  def down
    drop_table :canonical_profiles_v2
  end
end
