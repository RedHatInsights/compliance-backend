# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventorySystemLock do
  let(:system_id) { SecureRandom.uuid }

  it 'uses the shared transaction lock namespace and row lock' do
    connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    relation = instance_double(ActiveRecord::Relation)
    helper = Class.new { include InventorySystemLock }.new
    quoted_key = Faker::Lorem.word

    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    allow(connection).to receive(:quote).with("inventory-system:#{system_id}").and_return(quoted_key)
    allow(System).to receive(:unscoped).and_return(relation)
    allow(relation).to receive(:where).with(id: system_id).and_return(relation)
    allow(relation).to receive(:lock).and_return(relation)

    expect(ActiveRecord::Base).to receive(:transaction).and_yield
    expect(connection).to receive(:execute).with(
      "SELECT pg_advisory_xact_lock(hashtextextended(#{quoted_key}, 0))"
    )
    expect(relation).to receive(:load)

    ActiveRecord::Base.transaction do
      helper.send(:lock_inventory_system, system_id)
    end
  end
end
