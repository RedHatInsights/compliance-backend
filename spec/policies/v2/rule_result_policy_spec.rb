# frozen_string_literal: true

require 'rails_helper'

describe V2::RuleResultPolicy do
  let(:user) { FactoryBot.create(:v2_user) }

  let(:report) do
    FactoryBot.create(
      :v2_report,
      assigned_system_count: 0,
      os_major_version: 8,
      supports_minors: [0],
      account: user.account
    )
  end

  let(:system) do
    FactoryBot.create(:system, policy_id: report.id, with_test_result: true, account: user.account, groups: groups)
  end

  let(:test_result) { system.test_results.first }

  let!(:items) do
    test_result.tailoring.rules.map do |rule|
      FactoryBot.create(:v2_rule_result, rule_id: rule.id, test_result_id: test_result.id)
    end
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
    system = FactoryBot.create(:system, policy_id: report.id, with_test_result: true, account: acc)
    test_result = system.test_results.first
    test_result.tailoring.rules.map do |rule|
      FactoryBot.create(:v2_rule_result, rule_id: rule.id, test_result_id: test_result.id)
    end
  end

  context 'org-level access without groups' do
    let(:groups) { [] }

    before { stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ) }

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::RuleResult.joins(:system)).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::RuleResult.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'group-level access' do
    let(:groups) { [{ id: group }] }
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

      system = FactoryBot.create(
        :system,
        policy_id: report.id,
        with_test_result: true,
        account: user.account,
        group_count: 1
      )
      test_result = system.test_results.first
      test_result.tailoring.rules.map do |rule|
        FactoryBot.create(:v2_rule_result, rule_id: rule.id, test_result_id: test_result.id)
      end
    end

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::RuleResult.joins(:system)).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::RuleResult.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'ungrouped access' do
    let(:groups) { [] }

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

      system = FactoryBot.create(
        :system,
        policy_id: report.id,
        with_test_result: true,
        account: user.account,
        group_count: (1..4).to_a.sample
      )
      test_result = system.test_results.first
      test_result.tailoring.rules.map do |rule|
        FactoryBot.create(:v2_rule_result, rule_id: rule.id, test_result_id: test_result.id)
      end
    end

    it 'allows displaying entities' do
      expect(Pundit.policy_scope(user, V2::RuleResult.joins(:system)).to_set).to eq(items.to_set)
    end

    it 'authorizes the index and show actions' do
      items.each do |item|
        expect(Pundit.authorize(user, item, :show?)).to be_truthy
      end

      V2::RuleResult.where.not(id: items.map(&:id)).find_each do |item|
        expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
