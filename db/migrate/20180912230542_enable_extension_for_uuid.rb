# frozen_string_literal: true

# Use UUIDs as primary keys instead of plain integer IDs
class EnableExtensionForUuid < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto'
  end
end
