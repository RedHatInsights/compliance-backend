class RemoveExternalPolicies < ActiveRecord::Migration[5.2]
  def change
    ExternalPolicyRemover.run!
  end
end
