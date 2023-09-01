class CreateSecurityGuides < ActiveRecord::Migration[7.0]
  def change
    create_view :security_guides
  end
end
