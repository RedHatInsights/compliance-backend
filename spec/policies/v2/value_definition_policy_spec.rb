# frozen_string_literal: true

require 'rails_helper'

describe V2::RulePolicy do
  let(:user) { FactoryBot.create(:user) }
  let!(:value_definitions) { FactoryBot.create_list(:v2_value_definition, 10) }

  it 'allows displaying all value definitions' do
    expect(Pundit.policy_scope(user, V2::ValueDefinition)).to eq(value_definitions)
  end

  it 'authorizes the index and show actions' do
    value_definitions.each do |value_definition|
      assert Pundit.authorize(user, value_definition, :index?)
      assert Pundit.authorize(user, value_definition, :show?)
    end
  end
end
