# frozen_string_literal: true

RSpec.shared_examples 'globally available' do
  let(:klass) { items.first.class }

  it 'allows displaying all entities' do
    expect(Pundit.policy_scope(user, klass).to_set).to eq(items.to_set)
  end

  it 'authorizes the index and show actions' do
    items.each do |item|
      assert Pundit.authorize(user, item, :index?)
      assert Pundit.authorize(user, item, :show?)
    end
  end
end
