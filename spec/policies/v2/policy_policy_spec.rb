# frozen_string_literal: true

require 'rails_helper'

describe V2::PolicyPolicy do
  let(:user) { FactoryBot.create(:user) }
  let!(:items) { FactoryBot.create_list(:v2_policy, 20, account: user.account) }

  before { FactoryBot.create_list(:v2_policy, 10, account: FactoryBot.create(:v2_account)) }

  it 'allows displaying entities related to current user' do
    expect(Pundit.policy_scope(user, V2::Policy).to_set).to eq(items.to_set)
  end

  it 'authorizes the index and show actions' do
    items.each do |item|
      expect(Pundit.authorize(user, item, :show?)).to be_truthy
      expect(Pundit.authorize(user, item, :update?)).to be_truthy
      expect(Pundit.authorize(user, item, :destroy?)).to be_truthy
    end

    V2::Policy.where.not(id: items.map(&:id)).find_each do |item|
      expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
      expect { Pundit.authorize(user, item, :update?) }.to raise_error(Pundit::NotAuthorizedError)
      expect { Pundit.authorize(user, item, :destroy?) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
