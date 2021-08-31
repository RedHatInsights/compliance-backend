class RemoveDanglingAccounts < ActiveRecord::Migration[5.2]
  def up
    DanglingAccountRemover.run!
  end

  def down
    # nop
  end
end
