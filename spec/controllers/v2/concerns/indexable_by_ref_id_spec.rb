# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass there all the parent IDs and
# IDs to search for as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456, id: 789 } }
#
# it_behaves_like 'individual', :security_guide, :profile
# ```
#
# In a non-nested case the let block should the ID to search for and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { { id: 789 } }
#
# it_behaves_like 'individual'
# ```
#
RSpec.shared_examples 'indexable by ref_id' do |*parents|
  let(:passable_params) do
    extra_params.reject { |_, ep| ep.is_a?(ActiveRecord::Base) }
  end

  it 'returns item by ref_id' do
    expected = hash_including('data' => {
                                'id' => item.id,
                                'type' => described_class.controller_name.singularize,
                                **attributes.each_with_object({}) do |(key, value), obj|
                                  obj[key.to_s] = item.send(value)
                                end
                              })

    get :show, params: passable_params.merge(parents: parents, id: item.ref_id.parameterize)

    expect(response.parsed_body).to match(expected)
  end

  context 'with nonexistent ref_id' do
    it 'returns not_found' do
      get :show, params: passable_params.merge(parents: parents, id: 'incorrect')

      expect(response).to have_http_status :not_found
    end
  end
end
