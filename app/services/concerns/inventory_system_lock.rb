# frozen_string_literal: true

# Coordinates database work for events affecting the same inventory system.
module InventorySystemLock
  extend ActiveSupport::Concern

  private

  def lock_inventory_system(system_id)
    connection = ActiveRecord::Base.connection
    key = connection.quote("inventory-system:#{system_id}")
    connection.execute("SELECT pg_advisory_xact_lock(hashtextextended(#{key}, 0))")
    System.unscoped.where(id: system_id).lock.load
  end
end
