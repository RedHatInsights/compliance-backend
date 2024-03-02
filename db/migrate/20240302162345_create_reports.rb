class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_view :reports
  end
end
