# frozen_string_literal: true

require 'rails_helper'

describe V2::ProfilePolicy do
  let(:user) { FactoryBot.create(:user) }
  let!(:profiles) { FactoryBot.create_list(:v2_profile, 10) }

  it 'allows displaying all profiles' do
    expect(Pundit.policy_scope(user, V2::Profile)).to eq(profiles)
  end

  it 'authorizes the index and show actions' do
    profiles.each do |profile|
      assert Pundit.authorize(user, profile, :index?)
      assert Pundit.authorize(user, profile, :show?)
    end
  end
end
