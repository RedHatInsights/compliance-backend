class CreateReportSystemsV2Table < ActiveRecord::Migration[8.0]
  def change
    create_table :report_systems_v2, id: :uuid do |t|
      t.uuid :report_id
      t.uuid :system_id

      t.timestamps
    end

    add_index :report_systems_v2, [:report_id, :system_id], unique: true, name: 'index_report_systems_v2_on_report_id_and_system_id'
    add_index :report_systems_v2, [:report_id], name: 'index_report_systems_v2_on_report_id'
    add_index :report_systems_v2, [:system_id], name: 'index_report_systems_v2_on_system_id'
  end
end
