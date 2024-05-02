# frozen_string_literal: true

require 'rails_helper'

describe V2::ReportPolicy do
  let(:user) { FactoryBot.create(:v2_user) }
  let!(:items) do
    FactoryBot.create_list(
      :v2_report, 20,
      account: user.account,
      os_major_version: 8,
      supports_minors: [0, 1]
    )
  end

  it 'allows displaying entities related to current user' do
    expect(Pundit.policy_scope(user, V2::Report).to_set).to eq(items.to_set)
  end

  it 'authorizes the show, update and destroy actions' do
    items.each { |item| expect(Pundit.authorize(user, item, :show?)).to be_truthy }

    V2::Policy.where.not(id: items.map(&:id)).find_each do |item|
      expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
