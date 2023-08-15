# frozen_string_literal: true

# --- How to use ---
# Create yaml with name matching tested controller in the following format:
# `spec/controllers/v2/search/tested_controler.yaml`
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
# parents - array of parental ActiveRecord models
#         - usage: it_behaves_like 'searchable', Parent1, Parent2
# extra_params - extra parameters to be passed into request
#              - usage:
#                 it_behaves_like 'searchable', parents do
#                   let(:extra_params) { { *extra parameters* } }
#                 end

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

      nested_route(*parents) do |mocked_parents|
        get :index, params: extra_params.merge(
          { filter: search[:query] },
          parents: mocked_parents
        )
      end

      expect(response_body_data).to match_array(found.map { |item| hash_including('id' => item.id) })
    end
  end
end
