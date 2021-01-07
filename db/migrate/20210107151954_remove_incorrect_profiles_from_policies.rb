class RemoveIncorrectProfilesFromPolicies < ActiveRecord::Migration[5.2]
  def change
    IncorrectProfileRemover.run!
  end
end
