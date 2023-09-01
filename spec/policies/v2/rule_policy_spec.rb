# frozen_string_literal: true

require 'rails_helper'

describe V2::RulePolicy do
  let(:user) { FactoryBot.create(:user) }
  let!(:rules) { FactoryBot.create_list(:v2_rule, 10) }

  it 'allows displaying all rules' do
    expect(Pundit.policy_scope(user, V2::Rule)).to eq(rules)
  end

  it 'authorizes the index and show actions' do
    rules.each do |rule|
      assert Pundit.authorize(user, rule, :index?)
      assert Pundit.authorize(user, rule, :show?)
    end
  end
end
