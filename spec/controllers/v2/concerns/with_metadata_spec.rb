# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of model classes similarly to how they are defined in the routes. It is also
# required to set the `extra_params` variable in a let block and pass all the parent IDs there
# as a hash. For example:
# ```
# include_examples 'with_metadata', SecurityGuide, Profile do
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
