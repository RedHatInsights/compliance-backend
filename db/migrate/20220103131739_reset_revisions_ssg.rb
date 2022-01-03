class ResetRevisionsSsg < ActiveRecord::Migration[6.0]
  def up
    Revision.find_by(name: 'datastreams')&.delete
  end

  def down
    #nop
  end
end
