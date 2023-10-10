# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass there all the parent IDs and
# IDs to search for as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456, id: 789 } }
#
# it_behaves_like 'resource', :security_guide, :profile
# ```
#
# In a non-nested case the let block should the ID to search for and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { { id: 789 } }
#
# it_behaves_like 'resource'
# ```
#
RSpec.shared_examples 'resource' do |*parents|
  it 'returns item by id' do
    expected = hash_including('data' => {
                                'id' => item.id,
                                'type' => described_class.controller_name.chop,
                                **attributes.each_with_object({}) do |(key, value), obj|
                                  obj[key.to_s] = item.send(value)
                                end
                              })

    get :show, params: extra_params.merge(parents: parents)

    expect(response.parsed_body).to match(expected)
  end

  context 'under incorrect parent', if: parents.present? do
    it 'returns not_found' do
      get :show, params: notfound_params.merge(parents: parents)

      expect(response).to have_http_status :not_found
    end
  end
end
