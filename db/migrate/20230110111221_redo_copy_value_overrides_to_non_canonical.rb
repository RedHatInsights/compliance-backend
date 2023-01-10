class RedoCopyValueOverridesToNonCanonical < ActiveRecord::Migration[7.0]
  def up
    CopyValueOverridesToNonCanonical.run!
  end
end
