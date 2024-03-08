# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass there all the parent IDs and
# IDs to search for as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456, id: 789 } }
#
# it_behaves_like 'indexable', :ref_id, :security_guide, :profile
# ```
#
# In a non-nested case the let block should the ID to search for and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { { id: 789 } }
#
# it_behaves_like 'indexable', :ref_id
# ```
# In some cases, however, additional ActiveRecord objects and scalar values are required for
# invoking a factory. Therefore, if you don't want these objects to be passed to the `params`
# of the request, you can safely specify ActiveRecord objects in the `extra_params`. For scalar
# values you can use the `pw()` wrapper method that makes sure that the value is only passed to
# the factory and not to the URL params.
# ```
# let(:extra_params) { { account: FactoryBot.create(:v2_account), system_count: pw(10) } }
#
# it_behaves_like 'indexable', :ref_id
# ```
#
RSpec.shared_examples 'indexable' do |field, *parents|
  let(:passable_params) { reject_nonscalar(extra_params) }

  it "returns item by #{field}" do
    expected = hash_including('data' => {
                                'id' => item.id,
                                'type' => described_class.controller_name.singularize,
                                **attributes.each_with_object({}) do |(key, value), obj|
                                  obj[key.to_s] = item.send(value)
                                end
                              })

    get :show, params: passable_params.merge(parents: parents, id: item.send(field).parameterize)

    expect(response.parsed_body).to match(expected)
  end
end
