class CreateV1PoliciesView < ActiveRecord::Migration[8.0]
  def change
    create_view :v1_policies
  end
end
