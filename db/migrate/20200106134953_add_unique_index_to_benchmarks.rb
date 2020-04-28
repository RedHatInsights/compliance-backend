require 'profile'

class AddUniqueIndexToBenchmarks < ActiveRecord::Migration[5.2]
  class ::Profile < ApplicationRecord
    def destroy_policy_test_results
      DestroyProfilesJob.new.perform(policy_profiles.pluck(:id))
    end
  end

  def up
    DuplicateBenchmarkResolver.run!

    add_index(:benchmarks, %i[ref_id version], unique: true)
  end

  def down
    remove_index(:benchmarks, %i[ref_id version])
  end
end
