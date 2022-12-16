class ValueOverridesToNonCanonicalProfiles < ActiveRecord::Migration[7.0]
  def up
    CopyValueOverridesToNonCanonical.run!
  end
end
