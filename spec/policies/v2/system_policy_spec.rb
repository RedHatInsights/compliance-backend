# frozen_string_literal: true

require 'rails_helper'

describe V2::SystemPolicy do
  let(:user) { FactoryBot.create(:v2_user) }
  let!(:items) { FactoryBot.create_list(:system, 20, account: user.account) }

  before do
    FactoryBot.create_list(:system, 10, account: FactoryBot.create(:v2_account))
  end

  context 'org-level access without groups' do
    before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ) }

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::System).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::System.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'group-level access' do
    let(:group) { Faker::Internet.uuid }

    before do
      stub_rbac_permissions(
        Rbac::INVENTORY_HOSTS_READ => [{
          attribute_filter: {
            key: 'group.id',
            operation: 'in',
            value: [group]
          }
        }]
      )
      FactoryBot.create_list(:system, 10, account: user.account, group_count: 1)
    end

    let!(:items) { FactoryBot.create_list(:system, 20, account: user.account, groups: [{ id: group }]) }

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::System).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::System.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'ungrouped access' do
    before do
      stub_rbac_permissions(
        Rbac::INVENTORY_HOSTS_READ => [{
          attribute_filter: {
            key: 'group.id',
            operation: 'in',
            value: [nil]
          }
        }]
      )

      FactoryBot.create_list(:system, 10, account: user.account, group_count: (1..4).to_a.sample)
    end

    let!(:items) { FactoryBot.create_list(:system, 20, account: user.account) }

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::System).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::System.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'cert_auth' do
    let(:owner_id) { Faker::Internet.uuid }
    let(:user) { FactoryBot.create(:v2_user, :with_cert_auth, system_owner_id: owner_id) }
    let(:items) { FactoryBot.create_list(:system, 1, account: user.account, owner_id: owner_id) }

    context 'with matching owner_id' do
      it 'allows access to the system' do
        expect(Pundit.policy_scope(user, V2::System).to_set).to eq(items.to_set)
      end
    end

    context 'with mismatching owner_id' do
      let(:user) { FactoryBot.create(:v2_user, :with_cert_auth, system_owner_id: owner_id) }
      let(:items) { FactoryBot.create_list(:system, 1, account: user.account) }

      it 'restricts access to the system' do
        expect(Pundit.policy_scope(user, V2::System).to_set).to be_empty
      end
    end
  end

  context 'temporary table optimization for large group lists' do
    let(:group1) { Faker::Internet.uuid }
    let(:group2) { Faker::Internet.uuid }
    let(:group3) { Faker::Internet.uuid }
    let(:large_group_list) { (1..60).map { Faker::Internet.uuid } }

    before do
      # Create systems with specific groups
      FactoryBot.create_list(:system, 5, account: user.account, groups: [{ id: group1 }])
      FactoryBot.create_list(:system, 5, account: user.account, groups: [{ id: group2 }])
      FactoryBot.create_list(:system, 5, account: user.account, groups: [{ id: group3 }])
    end

    context 'when Kessel is enabled and groups exceed threshold' do
      before do
        allow(Settings.kessel).to receive(:enabled).and_return(true)
        allow(Settings.kessel).to receive(:groups_temp_table_threshold).and_return(50)
        stub_rbac_permissions(
          Rbac::INVENTORY_HOSTS_READ => [{
            attribute_filter: {
              key: 'group.id',
              operation: 'in',
              value: large_group_list
            }
          }]
        )
      end

      it 'uses the temporary table approach' do
        scope = V2::SystemPolicy::Scope.new(user, V2::System)
        expect(scope.send(:requires_temp_table, large_group_list)).to be true
      end

      it 'returns correct results' do
        # Add one of our test groups to the large list
        large_group_list[0] = group1
        stub_rbac_permissions(
          Rbac::INVENTORY_HOSTS_READ => [{
            attribute_filter: {
              key: 'group.id',
              operation: 'in',
              value: large_group_list
            }
          }]
        )

        result = Pundit.policy_scope(user, V2::System)
        expect(result.count).to eq(5)
        expect(result.pluck(:groups).flatten.map { |g| g['id'] }.uniq).to eq([group1])
      end

      it 'creates and drops temporary table' do
        scope = V2::SystemPolicy::Scope.new(user, V2::System)
        conn = V2::System.connection

        expect(conn).to receive(:execute).with(/CREATE TEMP TABLE/).and_call_original
        expect(conn).to receive(:execute).with(/INSERT INTO/).and_call_original

        Pundit.policy_scope(user, V2::System).to_a
      end
    end

    context 'when Kessel is enabled but groups are below threshold' do
      let(:small_group_list) { [group1, group2] }

      before do
        allow(Settings.kessel).to receive(:enabled).and_return(true)
        allow(Settings.kessel).to receive(:groups_temp_table_threshold).and_return(50)
        stub_rbac_permissions(
          Rbac::INVENTORY_HOSTS_READ => [{
            attribute_filter: {
              key: 'group.id',
              operation: 'in',
              value: small_group_list
            }
          }]
        )
      end

      it 'does not use the temporary table approach' do
        scope = V2::SystemPolicy::Scope.new(user, V2::System)
        expect(scope.send(:requires_temp_table, small_group_list)).to be false
      end

      it 'returns correct results using standard approach' do
        result = Pundit.policy_scope(user, V2::System)
        expect(result.count).to eq(10)
        group_ids = result.pluck(:groups).flatten.map { |g| g['id'] }.uniq.sort
        expect(group_ids).to eq([group1, group2].sort)
      end
    end

    context 'when Kessel is disabled' do
      before do
        allow(Settings.kessel).to receive(:enabled).and_return(false)
        stub_rbac_permissions(
          Rbac::INVENTORY_HOSTS_READ => [{
            attribute_filter: {
              key: 'group.id',
              operation: 'in',
              value: large_group_list
            }
          }]
        )
      end

      it 'does not use the temporary table approach' do
        scope = V2::SystemPolicy::Scope.new(user, V2::System)
        expect(scope.send(:requires_temp_table, large_group_list)).to be false
      end
    end

    context 'when temporary table creation fails' do
      before do
        allow(Settings.kessel).to receive(:enabled).and_return(true)
        allow(Settings.kessel).to receive(:groups_temp_table_threshold).and_return(50)
        stub_rbac_permissions(
          Rbac::INVENTORY_HOSTS_READ => [{
            attribute_filter: {
              key: 'group.id',
              operation: 'in',
              value: large_group_list + [group1]
            }
          }]
        )
      end

      it 'falls back to standard approach and logs error' do
        scope = V2::SystemPolicy::Scope.new(user, V2::System)
        allow(scope).to receive(:create_temp_table).and_raise(ActiveRecord::StatementInvalid, 'Table creation failed')

        expect(Rails.logger).to receive(:error).with(/Temp table optimization failed/)

        result = Pundit.policy_scope(user, V2::System)
        # Should still return results using fallback
        expect(result.count).to eq(5)
      end
    end
  end
end
