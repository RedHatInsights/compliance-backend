# frozen_string_literal: true

require 'rails_helper'

describe SystemPolicy do
  let(:user) { FactoryBot.create(:user) }
  let!(:items) { FactoryBot.create_list(:system, 20, account: user.account) }

  before do
    FactoryBot.create_list(:system, 10, account: FactoryBot.create(:account))
  end

  context 'org-level access without groups' do
    before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ) }

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, System).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      System.where.not(id: items.map(&:id)).find_each do |item|
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
      expect(Pundit.policy_scope(user, System).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      System.where.not(id: items.map(&:id)).find_each do |item|
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
      expect(Pundit.policy_scope(user, System).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      System.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'cert_auth' do
    let(:owner_id) { Faker::Internet.uuid }
    let(:user) { FactoryBot.create(:user, :with_cert_auth, system_owner_id: owner_id) }
    let(:items) { FactoryBot.create_list(:system, 1, account: user.account, owner_id: owner_id) }

    context 'with matching owner_id' do
      it 'allows access to the system' do
        expect(Pundit.policy_scope(user, System).to_set).to eq(items.to_set)
      end
    end

    context 'with mismatching owner_id' do
      let(:user) { FactoryBot.create(:user, :with_cert_auth, system_owner_id: owner_id) }
      let(:items) { FactoryBot.create_list(:system, 1, account: user.account) }

      it 'restricts access to the system' do
        expect(Pundit.policy_scope(user, System).to_set).to be_empty
      end
    end

    it 'merges native owner predicates through aliased system joins' do
      expect do
        PolicySystem.joins(:system).merge_with_alias(Pundit.policy_scope(user, System)).to_sql
      end.not_to raise_error
    end
  end

  context 'satellite cert_auth' do
    let(:owner_id) { Faker::Internet.uuid }
    let(:subscription_manager_id) { Faker::Internet.uuid }
    let(:forwarded_subscription_manager_id) { subscription_manager_id }
    let(:user) do
      FactoryBot.create(
        :user,
        :with_cert_auth,
        system_owner_id: owner_id,
        cert_type: 'satellite',
        identity_type: 'System'
      ).tap do |created|
        created.account.forwarded_subscription_manager_id = forwarded_subscription_manager_id
      end
    end
    let!(:matching_system) do
      FactoryBot.create(
        :system,
        account: user.account,
        owner_id: owner_id,
        subscription_manager_id: subscription_manager_id
      )
    end
    let!(:same_owner_system) do
      FactoryBot.create(
        :system,
        account: user.account,
        owner_id: owner_id,
        subscription_manager_id: Faker::Internet.uuid
      )
    end
    let!(:other_owner_system) do
      FactoryBot.create(
        :system,
        account: user.account,
        owner_id: Faker::Internet.uuid,
        subscription_manager_id: subscription_manager_id
      )
    end

    it 'scopes to that subscription_manager_id' do
      expect(Pundit.policy_scope(user, System).to_set).to eq([matching_system].to_set)
    end

    context 'when the forwarded header is absent' do
      let(:forwarded_subscription_manager_id) { nil }

      it 'returns all owner_id matches' do
        expect(Pundit.policy_scope(user, System).to_set).to eq([matching_system, same_owner_system].to_set)
      end
    end
  end

  context 'non-satellite cert_auth' do
    let(:owner_id) { Faker::Internet.uuid }
    let(:subscription_manager_id) { Faker::Internet.uuid }
    let(:user) do
      FactoryBot.create(
        :user,
        :with_cert_auth,
        system_owner_id: owner_id,
        cert_type: 'system',
        identity_type: 'System'
      ).tap do |created|
        created.account.forwarded_subscription_manager_id = subscription_manager_id
      end
    end
    let!(:owner_systems) do
      [
        FactoryBot.create(
          :system,
          account: user.account,
          owner_id: owner_id,
          subscription_manager_id: subscription_manager_id
        ),
        FactoryBot.create(
          :system,
          account: user.account,
          owner_id: owner_id,
          subscription_manager_id: Faker::Internet.uuid
        )
      ]
    end

    it 'ignores the forwarded header' do
      expect(Pundit.policy_scope(user, System).to_set).to eq(owner_systems.to_set)
    end
  end

  context 'no permissions' do
    before do
      allow(user).to receive(:inventory_groups).and_return([])
    end

    it 'denies access to index' do
      expect { Pundit.authorize(user, System, :index?) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it 'allows scoping (returns empty scope)' do
      expect(Pundit.policy_scope(user, System).to_a).to be_empty
    end
  end
end
