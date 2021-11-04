class DeleteUpstreamProfiles < ActiveRecord::Migration[5.2]
  def up
    UpstreamProfileRemover.run!
    DanglingAccountRemover.run!
  end

  def down
    # nop
  end
end
