class AddUniqueIndexToBenchmarks < ActiveRecord::Migration[5.2]
  def up
    Settings.async = false

    DuplicateBenchmarkResolver.run!

    add_index(:benchmarks, %i[ref_id version], unique: true)
  end

  def down
    remove_index(:benchmarks, %i[ref_id version])
  end
end
