class CreateV2Policies < ActiveRecord::Migration[7.0]
  def change
    create_view :v2_policies
  end
end
