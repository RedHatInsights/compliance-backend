# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# include_examples 'with_metadata', :security_guide, :profile do
#   let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
# end
# ```
#
# In a non-nested case this example can be simply included as:
# ```
# include_examples 'with_metadata'
# ```
#
RSpec.shared_examples 'with metadata' do |*parents|
  let(:meta_keys) { %w[total limit offset relationships] }
  let(:item_count) { 10 }
  let(:extra_params) { {} }

  it 'contains total, limit, offset and relationships keys' do
    get :index, params: extra_params.merge(parents: parents)

    expect(response.parsed_body['meta'].keys).to contain_exactly(*meta_keys)
  end

  it 'has correct total in metadata' do
    items

    get :index, params: extra_params.merge(parents: parents)

    expect(response.parsed_body['meta']['total']).to eq(item_count)
  end
end
