class ScopedSlugIndex < ActiveRecord::Migration[7.0]
  class Rule < ActiveRecord::Base; end

  def up
    remove_index :rules, :slug, unique: true
    Rule.update_all("slug = LOWER(REPLACE(ref_id, '.', '-'))")
    add_index :rules, [:slug, :benchmark_id], unique: true
  end

  def down
    remove_index :rules, [:slug, :benchmark_id], unique: true
    Rule.update_all("slug = CONCAT(LOWER(REPLACE(ref_id, '.', '-')), '-', benchmark_id)")
    add_index :rules, :slug, unique: true
  end
end
