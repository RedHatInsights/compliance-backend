class ResetDatastreamsFixes < ActiveRecord::Migration[7.1]
  def up
    Revision.find_by(name: 'datastreams')&.delete
  end
end
