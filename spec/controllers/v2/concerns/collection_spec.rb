# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
#
# it_behaves_like 'collection', :security_guide, :profile
# ```
#
# In a non-nested case the let block should contain an empty hash and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { {} }
#
# it_behaves_like 'collection'
# ```
#
RSpec.shared_examples 'collection' do |*parents|
  it 'returns base fields for each result' do
    collection = items.map do |item|
      hash_including(
        'id' => item.id,
        'type' => described_class.controller_name.chop,
        **attributes.each_with_object({}) do |(key, value), obj|
          obj[key.to_s] = item.send(value)
        end
      )
    end

    get :index, params: extra_params.merge(parents: parents)

    expect(response).to have_http_status :ok
    expect(response_body_data).to match_array(collection)

    response_body_data.each do |item|
      expect(item.keys.count).to eq(attributes.keys.count + 2)
    end
  end

  context 'under incorrect parent', if: parents.present? do
    let(:parent) { FactoryBot.create(:"v2_#{parents.first}") }

    it 'returns not_found' do
      get :index, params: extra_params.merge(parents: parents)

      expect(response_body_data).to be_empty
    end
  end

  context 'Unathorized' do
    let(:rbac_allowed?) { false }

    it 'responds with unauthorized status' do
      get :index, params: extra_params.merge(parents: parents)

      expect(response).to have_http_status :forbidden
    end
  end
end
