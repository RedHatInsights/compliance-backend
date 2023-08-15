# frozen_string_literal: true

RSpec.shared_examples 'with metadata' do |*parents|
  let(:meta_keys) { %w[total limit offset relationships] }
  let(:item_count) { 10 }
  let(:extra_params) { {} }

  it 'contains total, limit, offset and relationships keys' do
    nested_route(*parents) do |mocked_parents|
      get :index, params: extra_params.merge(parents: mocked_parents)
    end

    expect(response.parsed_body['meta'].keys).to contain_exactly(*meta_keys)
  end

  it 'has correct total in metadata' do
    items

    nested_route(*parents) do |mocked_parents|
      get :index, params: extra_params.merge(parents: mocked_parents)
    end

    expect(response.parsed_body['meta']['total']).to eq(item_count)
  end
end
