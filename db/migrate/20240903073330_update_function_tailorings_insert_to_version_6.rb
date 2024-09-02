class UpdateFunctionTailoringsInsertToVersion6 < ActiveRecord::Migration[7.1]
  def change
    update_function :tailorings_insert, version: 6, revert_to_version: 5
    create_trigger :tailorings_insert, on: :tailorings
  end
end
