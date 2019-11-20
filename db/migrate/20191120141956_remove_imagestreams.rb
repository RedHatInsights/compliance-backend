class RemoveImagestreams < ActiveRecord::Migration[5.2]
  def change
    drop_table :profile_imagestreams
    drop_table :imagestreams
  end
end
