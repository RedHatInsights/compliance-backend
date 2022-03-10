class ResetRevisionsMarchTenth < ActiveRecord::Migration[7.0]
  def up
    Revision.find_by(name: 'datastreams')&.delete
  end

  def down
    # nop
  end
end
