class AddParentProfileIdToProfiles < ActiveRecord::Migration[5.2]
  def down
    remove_reference :profiles, :parent_profile
  end

  def up
    add_reference :profiles, :parent_profile, type: :uuid, foreign_key: { to_table: :profiles }

    Xccdf::Benchmark.find_by(ref_id: 'phony_ref_id')&.destroy
    ParentProfileAssociator.run!
  end
end
