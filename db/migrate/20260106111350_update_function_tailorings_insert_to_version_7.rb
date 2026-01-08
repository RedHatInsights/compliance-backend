class UpdateFunctionTailoringsInsertToVersion7 < ActiveRecord::Migration[8.0]
  def change
    drop_trigger :tailorings_insert, on: :tailorings, revert_to_version: 1
    update_function :tailorings_insert, version: 7, revert_to_version: 6
    create_trigger :tailorings_insert, on: :tailorings
  end
end
