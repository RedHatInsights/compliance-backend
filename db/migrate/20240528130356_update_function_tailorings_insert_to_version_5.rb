class UpdateFunctionTailoringsInsertToVersion5 < ActiveRecord::Migration[7.1]
  def change
    drop_trigger :tailorings_insert, on: :tailorings
    update_function :tailorings_insert, version: 5, revert_to_version: 4
    create_trigger :tailorings_insert, on: :tailorings
  end
end
