class CreateV2Rules < ActiveRecord::Migration[7.0]
  def change
    create_view :v2_rules
  end
end
