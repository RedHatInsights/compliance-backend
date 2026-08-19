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
# let(:extra_params) { { account: FactoryBot.create(:account), system_count: pw(10) } }
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
    it 'ANDs tags with different namespace/key combinations' do
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

    it 'ANDs different keys within the same namespace' do
      matching, only_location = selected
      matching.update(
        tags: [
          { namespace: 'satellite', key: 'location', value: 'Raleigh' },
          { namespace: 'satellite', key: 'organization', value: 'HCC-Lab' }
        ]
      )
      only_location.update(
        tags: [{ namespace: 'satellite', key: 'location', value: 'Raleigh' }]
      )

      get :index, params: passable_params.merge(
        parents: parents,
        tags: ['satellite/location=Raleigh', 'satellite/organization=HCC-Lab']
      )

      expect(response_body_data).to match_array([hash_including('id' => matching.id)])
    end

    it 'ORs values that share the same namespace and key' do
      first, second = selected
      first.update(
        tags: [{ namespace: 'insights-client', key: 'Public IPv4', value: '18.116.53.70' }]
      )
      second.update(
        tags: [{ namespace: 'insights-client', key: 'Public IPv4', value: '18.117.167.99' }]
      )

      get :index, params: passable_params.merge(
        parents: parents,
        tags: [
          'insights-client/Public IPv4=18.116.53.70',
          'insights-client/Public IPv4=18.117.167.99'
        ]
      )

      expect(response_body_data).to match_array(selected.map { |item| hash_including('id' => item.id) })
    end

    it 'combines AND across keys with OR within the same key' do
      matching, partial = selected
      matching.update(
        tags: [
          { namespace: 'satellite', key: 'location', value: 'Raleigh' },
          { namespace: 'satellite', key: 'organization', value: 'HCC-Lab' },
          { namespace: 'insights-client', key: 'security', value: 'strict' },
          { namespace: 'insights-client', key: 'Public IPv4', value: '18.116.53.70' }
        ]
      )
      partial.update(
        tags: [
          { namespace: 'satellite', key: 'location', value: 'Raleigh' },
          { namespace: 'satellite', key: 'organization', value: 'HCC-Lab' },
          { namespace: 'insights-client', key: 'Public IPv4', value: '18.117.167.99' }
        ]
      )

      get :index, params: passable_params.merge(
        parents: parents,
        tags: [
          'satellite/location=Raleigh',
          'satellite/organization=HCC-Lab',
          'insights-client/security=strict',
          'insights-client/Public IPv4=18.116.53.70',
          'insights-client/Public IPv4=18.117.167.99'
        ]
      )

      expect(response_body_data).to match_array([hash_including('id' => matching.id)])
    end
  end
end

RSpec.shared_examples 'taggable_show' do |*parents|
  let(:passable_params) { reject_nonscalar(extra_params) }

  context 'when system belongs to a different organization scope' do
    it 'prevents access via direct ID lookup' do
      item.update(tags: [{ namespace: 'sat_iam', key: 'scope', value: 'U:"admin"O:"ACME"L:"Default"' }])

      get :show, params: passable_params.merge(
        parents: parents, tags: ['sat_iam/scope=U:"operator"O:"Globex"L:"Springfield"']
      )

      expect(response).to have_http_status :not_found
    end
  end

  context 'with matching scope tag' do
    it 'returns the item' do
      item.update(tags: [{ namespace: 'sat_iam', key: 'scope', value: 'U:"admin"O:"ACME"L:"Default"' }])

      get :show, params: passable_params.merge(parents: parents, tags: ['sat_iam/scope=U:"admin"O:"ACME"L:"Default"'])

      expect(response).to have_http_status :ok
      expect(response.parsed_body.dig('data', 'id')).to eq(item.id)
    end
  end

  context 'with scope tag for a different user in the same organization' do
    it 'returns not_found' do
      item.update(tags: [{ namespace: 'sat_iam', key: 'scope', value: 'U:"admin"O:"ACME"L:"Default"' }])

      get :show, params: passable_params.merge(parents: parents, tags: ['sat_iam/scope=U:"viewer"O:"ACME"L:"NYC"'])

      expect(response).to have_http_status :not_found
    end
  end

  context 'without tags param' do
    it 'returns the item without filtering' do
      get :show, params: passable_params.merge(parents: parents)

      expect(response).to have_http_status :ok
      expect(response.parsed_body.dig('data', 'id')).to eq(item.id)
    end
  end

  context 'with multiple matching tags' do
    it 'returns the item when all tags match' do
      item.update(
        tags: [
          { namespace: 'insights-client', key: 'environment', value: 'production' },
          { namespace: 'operations', key: 'team', value: 'platform' }
        ]
      )

      get :show, params: passable_params.merge(
        parents: parents,
        tags: ['insights-client/environment=production', 'operations/team=platform']
      )

      expect(response).to have_http_status :ok
      expect(response.parsed_body.dig('data', 'id')).to eq(item.id)
    end
  end

  context 'with partially matching tags' do
    it 'returns not_found when not all tags match' do
      item.update(tags: [{ namespace: 'insights-client', key: 'environment', value: 'production' }])

      get :show, params: passable_params.merge(
        parents: parents,
        tags: ['insights-client/environment=production', 'operations/team=platform']
      )

      expect(response).to have_http_status :not_found
    end
  end

  context 'with untagged item and tags filter' do
    it 'returns not_found when item has no matching tags' do
      item.update(tags: [])

      get :show, params: passable_params.merge(parents: parents, tags: ['sat_iam/scope=U:"admin"O:"ACME"L:"Default"'])

      expect(response).to have_http_status :not_found
    end
  end

  context 'with invalid tag format' do
    it 'returns the item when tag cannot be parsed' do
      get :show, params: passable_params.merge(parents: parents, tags: ['no-slash-invalid'])

      expect(response).to have_http_status :ok
      expect(response.parsed_body.dig('data', 'id')).to eq(item.id)
    end
  end
end
