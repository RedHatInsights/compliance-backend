class UpdateFunctionTailoringsInsertToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_function :tailorings_insert, version: 2, revert_to_version: 1
  end
end
