# frozen_string_literal: true

require 'rails_helper'

describe V2::TestResultPolicy do
  let(:user) { FactoryBot.create(:v2_user) }

  let(:parent) do
    FactoryBot.create(
      :v2_report,
      assigned_system_count: 0,
      os_major_version: 8,
      supports_minors: [0],
      account: user.account
    )
  end

  let!(:items) do
    FactoryBot.create_list(
      :system, 20, policy_id: parent.id, with_test_result: true, account: user.account
    ).map { |sys| sys.test_results.first }
  end

  before do
    acc = FactoryBot.create(:v2_account)
    report = FactoryBot.create(
      :v2_report,
      assigned_system_count: 0,
      os_major_version: 8,
      supports_minors: [0],
      account: acc
    )
    FactoryBot.create_list(:system, 10, policy_id: report.id, with_test_result: true, account: acc)
  end

  context 'org-level access without groups' do
    before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ) }

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::TestResult.joins(:system)).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::TestResult.where.not(id: items.map(&:id)).find_each do |item|
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

      FactoryBot.create_list(
        :system, 10,
        policy_id: parent.id,
        with_test_result: true,
        account: user.account,
        group_count: 1
      )
    end

    let!(:items) do
      FactoryBot.create_list(
        :system, 20,
        policy_id: parent.id,
        with_test_result: true,
        account: user.account,
        groups: [{ id: group }]
      ).map { |sys| sys.test_results.first }
    end

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::TestResult.joins(:system)).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::TestResult.where.not(id: items.map(&:id)).find_each do |item|
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

      FactoryBot.create_list(
        :system, 10,
        policy_id: parent.id,
        with_test_result: true,
        account: user.account,
        group_count: (1..4).to_a.sample
      )
    end

    let!(:items) do
      FactoryBot.create_list(
        :system, 20,
        policy_id: parent.id,
        with_test_result: true,
        account: user.account
      ).map { |sys| sys.test_results.first }
    end

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::TestResult.joins(:system)).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::TestResult.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
