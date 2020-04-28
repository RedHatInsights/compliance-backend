require 'profile'

class AddUniqueIndexToProfiles < ActiveRecord::Migration[5.2]
  class ::Profile < ApplicationRecord
    def destroy_policy_test_results
      DestroyProfilesJob.new.perform(policy_profiles.pluck(:id))
    end
  end

  def up
    DuplicateProfileResolver.run!

    add_index(:profiles, %i[ref_id account_id benchmark_id], unique: true)
  end

  def down
    remove_index(:profiles, %i[ref_id account_id benchmark_id])
  end
end
