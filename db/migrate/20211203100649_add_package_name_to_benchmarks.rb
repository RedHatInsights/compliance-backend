class AddPackageNameToBenchmarks < ActiveRecord::Migration[5.2]
  def up
    add_column :benchmarks, :package_name, :string
  end

  def down
    remove_column :benchmarks, :package_name
  end
end
