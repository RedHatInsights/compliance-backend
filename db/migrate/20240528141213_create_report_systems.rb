class CreateReportSystems < ActiveRecord::Migration[7.1]
  def change
    create_view :report_systems
  end
end
