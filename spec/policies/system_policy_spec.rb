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

      it 'uses the native owner_id when JSONB disagrees' do
        items.first.update!(system_profile: { 'owner_id' => Faker::Internet.uuid })

        expect(Pundit.policy_scope(user, System).to_set).to eq(items.to_set)
      end
    end

    context 'with JSONB-only matching owner_id' do
      let(:items) do
        FactoryBot.create_list(
          :system,
          1,
          account: user.account,
          owner_id: Faker::Internet.uuid,
          system_profile: { 'owner_id' => owner_id }
        )
      end

      it 'does not grant access based on the JSONB owner_id' do
        expect(Pundit.policy_scope(user, System)).to be_empty
      end
    end

    context 'with native nil and matching JSONB owner_id' do
      let(:items) do
        FactoryBot.create_list(
          :system,
          1,
          account: user.account,
          owner_id: nil,
          system_profile: { 'owner_id' => owner_id }
        )
      end

      it 'does not fall back to the JSONB owner_id' do
        expect(Pundit.policy_scope(user, System)).to be_empty
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
