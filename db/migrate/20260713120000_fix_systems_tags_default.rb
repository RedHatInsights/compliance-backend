# frozen_string_literal: true

class FixSystemsTagsDefault < ActiveRecord::Migration[7.1]
  def up
    change_column_default :systems, :tags, from: {}, to: []
    execute "UPDATE systems SET tags = '[]'::jsonb WHERE tags = '{}'::jsonb"
  end

  def down
    # `up` collapses both {} and [] rows into [], so the original per-row shape
    # cannot be reconstructed. Restoring the {} default would also reintroduce
    # the array/object mismatch this migration fixes, leaving new rows with a
    # different JSONB shape than existing ones.
    raise ActiveRecord::IrreversibleMigration
  end
end
