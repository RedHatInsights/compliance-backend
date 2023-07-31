# frozen_string_literal: true

require 'rails_helper'

describe V2::SecurityGuidePolicy do
  let(:user) { FactoryBot.create(:user) }
  let!(:sgs) { FactoryBot.create_list(:v2_security_guide, 10) }

  it 'allows displaying all security guides' do
    expect(Pundit.policy_scope(user, V2::SecurityGuide)).to eq(sgs)
  end

  it 'authorizes the index and show actions' do
    sgs.each do |sg|
      assert Pundit.authorize(user, sg, :index?)
      assert Pundit.authorize(user, sg, :show?)
    end
  end
end
