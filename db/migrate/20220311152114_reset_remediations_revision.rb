class ResetRemediationsRevision < ActiveRecord::Migration[7.0]
  def up
    Revision.find_by(name: 'remediations')&.delete
  end

  def down
    # nop
  end
end
