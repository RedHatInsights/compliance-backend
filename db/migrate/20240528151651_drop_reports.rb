class DropReports < ActiveRecord::Migration[7.1]
  def change
    drop_view :reports, revert_to_version: 2
  end
end
