# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass there all the parent IDs and
# IDs to search for as a hash. For example:
# ```
# it_behaves_like 'show', :security_guide, :profile do
#   let(:extra_params) { { security_guide_id: 123, profile_id: 456, id: 789 } }
# end
# ```
#
# In a non-nested case this example can be included with passing the ID to search for:
# ```
# it_behaves_like 'show' do
#   let(:extra_params) { { id: 789 } }
# end
# ```
#
RSpec.shared_examples 'show' do |*parents|
  let(:extra_params) { {} }

  it 'returns item by id' do
    expected = hash_including('data' => {
                                'id' => item.id,
                                'type' => described_class.controller_name.chop,
                                'attributes' => attributes.each_with_object({}) do |(key, value), obj|
                                  obj[key.to_s] = item.send(value)
                                end
                              })

    get :show, params: extra_params.merge(parents: parents)

    expect(response.parsed_body).to match(expected)
  end
end
