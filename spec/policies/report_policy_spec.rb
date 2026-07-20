# frozen_string_literal: true

require 'rails_helper'

describe ReportPolicy do
  let(:user) { FactoryBot.create(:user) }
  let!(:items) do
    FactoryBot.create_list(
      :report, 20,
      account: user.account,
      os_major_version: 8,
      supports_minors: [0, 1]
    )
  end

  it 'allows displaying entities related to current user' do
    expect(Pundit.policy_scope(user, Report).to_set).to eq(items.to_set)
  end

  it 'authorizes the show, update and destroy actions' do
    items.each { |item| expect(Pundit.authorize(user, item, :show?)).to be_truthy }

    Policy.where.not(id: items.map(&:id)).find_each do |item|
      expect { Pundit.authorize(user, item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
