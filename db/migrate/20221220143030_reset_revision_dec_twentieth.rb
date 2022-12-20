class ResetRevisionDecTwentieth < ActiveRecord::Migration[7.0]
  def up
    Revision.find_by(name: 'datastreams')&.delete
  end
end
