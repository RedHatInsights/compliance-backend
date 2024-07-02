# frozen_string_literal: true

# --- How to use ---
# Create yaml with name matching tested controller in the following format:
# `spec/fixtures/files/searchable/tested_controler.yaml`
# ```yaml
# - :name: 'name of your test'
#   :entities:
#     :found: # entities that are supposed to be found by the search
#       - :factory: :name_of_your_factory
#         # fields passed to the factory
#     :not_found: # entities that are not supposed to be found by the search
#       - :factory: :name_of_your_factory
#         # fields passed to the factory
#   :query: 'query to search by'
# - :name: 'name of your test'
#   :entities:
#     :found: # entities that are supposed to be found by the search
#       - :factory: :name_of_your_factory
#         # fields passed to the factory
#     :not_found: # entities that are not supposed to be found by the search
#       - :factory: :name_of_your_factory
#         # fields passed to the factory
#   :query: 'query to search by'
#   :except_parents: [:parent] # skip the test if specified parents are present
#   :only_parents: [:parent] # run the test only if specified parents are present
# ```
#
# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
#
# it_behaves_like 'searchable', :security_guide, :profile
# ```
#
# In a non-nested case the let block should contain an empty hash and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { {} }
#
# it_behaves_like 'searchable'
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
# it_behaves_like 'searchable'
# ```
#
RSpec.shared_examples 'searchable' do |*parents|
  let(:passable_params) { reject_nonscalar(extra_params) }

  path = Rails.root.join('spec/fixtures/files/searchable', "#{described_class.name.demodulize.underscore}.yaml")
  searches = YAML.safe_load_file(path, permitted_classes: [Symbol])

  searches.each do |search|
    next if parents.to_a.intersect?(search[:except_parents].to_a)
    next if search[:only_parents] && !parents.to_a.intersect?(search[:only_parents])

    it search[:name] do
      found = search[:entities][:found].map do |h|
        entity = factory_params(h, extra_params)
        FactoryBot.create(entity.delete(:factory), **entity)
      end
      search[:entities][:not_found].map do |h|
        entity = factory_params(h, extra_params)
        FactoryBot.create(entity.delete(:factory), **entity)
      end

      get :index, params: passable_params.merge(filter: query_params(search[:query], extra_params), parents: parents)

      expect(response_body_data).to match_array(found.map { |item| hash_including('id' => item.id) })
    end
  end

  context 'implicit search' do
    it 'fails with unprocessble_entity' do
      get :index, params: passable_params.merge(filter: 'foo', parents: parents)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
