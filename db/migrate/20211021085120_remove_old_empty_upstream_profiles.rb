class RemoveOldEmptyUpstreamProfiles < ActiveRecord::Migration[5.2]
  def up
    profiles = Profile.canonical(false)
                      .joins(:parent_profile)
                      .left_outer_joins(:test_results)
                      .where('test_results.id': nil, 'parent_profiles_profiles.upstream': true)
                      .where("profiles.created_at < ?", 6.months.ago)
                      .where("profiles.updated_at < ?", 6.months.ago)

    ProfileRule.where(id: profiles.select(:id)).delete_all
    profiles.delete_all
  end

  def down
    # nop
  end
end
