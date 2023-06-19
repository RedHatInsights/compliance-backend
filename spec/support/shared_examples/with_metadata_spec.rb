# frozen_string_literal: true

RSpec.shared_examples 'with metadata' do
  let(:meta_keys) { %w[total limit offset relationships] }

  it 'contains total, limit, offset and relationships keys' do
    get :index

    expect(response.parsed_body['meta'].keys).to contain_exactly(*meta_keys)
  end

  it 'has correct total in metadata' do
    items

    get :index

    expect(response.parsed_body['meta']['total']).to eq(item_count)
  end
end
