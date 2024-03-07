# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
#
# it_behaves_like 'paginable', :security_guide, :profile
# ```
#
# In a non-nested case the let block should contain an empty hash and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { {} }
#
# it_behaves_like 'paginable'
# ```
#
# In some cases, however, additional ActiveRecord objects and scalar values are required for
# invoking a factory. Therefore, if you don't want these objects to be passed to the `params`
# of the request, you can safely specify ActiveRecord objects in the `extra_params`. For scalar
# values you can use the `pw()` wrapper method that makes sure that the value is only passed to
# the factory and not to the URL params.
# ```
# let(:extra_params) { { account: FactoryBot.create(:v2_account), system_count: pw(10) } }
#
# it_behaves_like 'paginable'
# ```
#
RSpec.shared_examples 'paginable' do |*parents|
  let(:item_count) { 20 } # We need more items to be created to test pagination properly

  # Do not pass instances of `ActiveRecord` or scalar values wrapped with `pw()` to the URL parameters
  let(:passable_params) { reject_nonscalar(extra_params) }

  [2, 5, 10, 15, 20].each do |per_page|
    it "returns with the requested #{per_page} records per page" do
      items # force creation
      get :index, params: passable_params.merge('limit' => per_page, parents: parents)

      expect(response_body_data.count).to eq(per_page)
    end

    20.times do |offset|
      it "returns #{per_page} records from the offset #{offset}" do
        nth_items = items[offset..(offset + per_page - 1)].map do |sg|
          hash_including(
            'id' => sg.id,
            'type' => subject.send(:resource).model_name.element
          )
        end

        get :index, params: passable_params.merge(
          'limit' => per_page,
          'offset' => offset,
          parents: parents
        )

        expect(response_body_data).to match_array(nth_items)
        expect(response.parsed_body['meta']['limit']).to eq(per_page)
        expect(response.parsed_body['meta']['offset']).to eq(offset)
      end
    end
  end
end
