# frozen_string_literal: true

require 'rails_helper'

describe TailoringPolicy do
  let(:canonical_profile) do
    FactoryBot.create(
      :profile,
      os_major_version: 9,
      ref_id_suffix: 'foo',
      supports_minors: [8]
    )
  end
  let(:user) { FactoryBot.create(:user) }
  let!(:item) do
    FactoryBot.create(
      :tailoring,
      policy: FactoryBot.create(
        :policy,
        account: user.account,
        profile: canonical_profile
      ),
      profile: canonical_profile,
      os_minor_version: 8
    )
  end

  before do
    FactoryBot.create(
      :tailoring,
      policy: FactoryBot.create(
        :policy,
        account: FactoryBot.create(:account),
        profile: canonical_profile
      ),
      profile: canonical_profile,
      os_minor_version: 8
    )
  end

  it 'allows displaying entities related to current user' do
    expect(Pundit.policy_scope(user, Tailoring).map(&:id)).to eq([item.id])
  end

  it 'authorizes the index and show actions' do
    expect(Pundit.authorize(user, item, :index?)).to be_truthy
    expect(Pundit.authorize(user, item, :show?)).to be_truthy

    Tailoring.where.not(id: item.id).find_each do |foreign_item|
      expect { Pundit.authorize(user, foreign_item, :show?) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
