class DeduplicateCanonicalProfiles < ActiveRecord::Migration[5.2]
  def up
    DuplicateCanonicalProfileResolver.run!
    add_index :profiles, %i[ref_id benchmark_id], unique: true, where: 'parent_profile_id is NULL'
  end

  def down
    remove_index :profiles, %i[ref_id benchmark_id]
  end
end
