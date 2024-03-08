# frozen_string_literal: true

# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
#
# it_behaves_like 'taggable', :security_guide, :profile
# ```
#
# In a non-nested case the let block should contain an empty hash and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { {} }
#
# it_behaves_like 'taggable'
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
# it_behaves_like 'taggable'
# ```
#
RSpec.shared_examples 'taggable' do |*parents|
  let(:passable_params) { reject_nonscalar(extra_params) }

  let(:item_count) { 10 }
  let(:selected) { items.take(2) }

  context 'looking for a single tag' do
    it 'returns systems matching the tag' do
      selected.map { |s| s.update(tags: [{ namespace: 'foo', key: 'bar', value: 'baz' }]) }

      get :index, params: passable_params.merge(parents: parents, tags: ['foo/bar=baz'])
      expect(response_body_data).to match_array(selected.map { |item| hash_including('id' => item.id) })
    end
  end

  context 'looking for multiple tags' do
    it 'returns systems matching all tags' do
      selected.map do |s|
        s.update(
          tags: [
            { namespace: 'foo', key: 'bar', value: 'baz' },
            { namespace: 'one', key: 'two', value: 'three' }
          ]
        )
      end

      get :index, params: passable_params.merge(parents: parents, tags: ['foo/bar=baz', 'one/two=three'])
      expect(response_body_data).to match_array(selected.map { |item| hash_including('id' => item.id) })
    end
  end
end
