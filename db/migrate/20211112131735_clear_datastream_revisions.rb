class ClearDatastreamRevisions < ActiveRecord::Migration[5.2]
  def up
    Revision.find_by(name: 'datastreams')&.delete
  end

  def down
    # NOP
  end
end
