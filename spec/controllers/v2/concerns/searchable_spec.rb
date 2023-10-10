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
RSpec.shared_examples 'searchable' do |*parents|
  path = Rails.root.join('spec/fixtures/files/searchable', "#{described_class.name.demodulize.underscore}.yaml")
  searches = YAML.safe_load_file(path, permitted_classes: [Symbol])

  searches.each do |search|
    it search[:name] do
      found = search[:entities][:found].map do |h|
        entity = factory_params(h, extra_params)
        FactoryBot.create(entity.delete(:factory), **entity)
      end
      search[:entities][:not_found].map do |h|
        entity = factory_params(h, extra_params)
        FactoryBot.create(entity.delete(:factory), **entity)
      end

      get :index, params: extra_params.merge(filter: search[:query], parents: parents)

      expect(response_body_data).to match_array(found.map { |item| hash_including('id' => item.id) })
    end
  end
end
