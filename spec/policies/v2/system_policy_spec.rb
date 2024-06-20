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
end
