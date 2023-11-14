# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
#
# include_examples 'with_metadata', :security_guide, :profile
# ```
#
# In a non-nested case the let block should contain an empty hash and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { {} }
#
# include_examples 'with_metadata'
# ```
#
# In some cases, however, additional ActiveRecord objects are required for invoking a factory.
# Therefore, if you don't want these objects to be passed to the `params` of the request, you
# can specify them in the `extra_params` as objects (i.e. without the `_id` suffix):
# ```
# let(:extra_params) { { account: FactoryBot.create(:account) } }
#
# it_behaves_like 'with_metadata'
# ```
#
RSpec.shared_examples 'with metadata' do |*parents|
  let(:passable_params) do
    extra_params.reject { |_, ep| ep.is_a?(ActiveRecord::Base) }
  end

  let(:item_count) { 10 }

  it 'contains total, limit, offset and relationships keys' do
    get :index, params: passable_params.merge(parents: parents)

    expect(response.parsed_body['meta'].keys).to contain_exactly(*%w[total limit offset])
  end

  it 'has correct total in metadata' do
    items

    get :index, params: passable_params.merge(parents: parents)

    expect(response.parsed_body['meta']['total']).to eq(item_count)
  end

  context 'offset is zero' do
    it 'has no previous link' do
      items

      get :index, params: passable_params.merge(
        limit: 2,
        offset: 0,
        parents: parents
      )

      expect(response.parsed_body['links'].keys).to contain_exactly(*%w[first last next])
    end
  end

  context 'offset between zero and number of entities' do
    it 'has all four links' do
      items

      get :index, params: passable_params.merge(
        limit: 2,
        offset: 2,
        parents: parents
      )

      expect(response.parsed_body['links'].keys).to contain_exactly(*%w[first last next previous])
    end
  end

  context 'offset equals the number of entities' do
    it 'has no next link' do
      items

      get :index, params: passable_params.merge(
        limit: 10,
        offset: 9,
        parents: parents
      )

      expect(response.parsed_body['links'].keys).to contain_exactly(*%w[first last previous])
    end
  end

  context 'offset is above the number of entities' do
    it 'has no next link' do
      items

      get :index, params: passable_params.merge(
        limit: 2,
        offset: 11,
        parents: parents
      )

      expect(response.parsed_body['links'].keys).to contain_exactly(*%w[first last previous])
    end
  end

  # When the list of results is empty, the last link's offset should equal 0.
  it 'has correct last offset when returning not_found' do
    get :index, params: passable_params.merge(parents: parents)

    expect(response_body_data).to be_empty
    expect(response.parsed_body['links']['last'][-1]).to eq('0')
  end
end
