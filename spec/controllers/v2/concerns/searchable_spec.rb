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

RSpec.shared_examples 'searchable' do
  path = Rails.root.join('spec/fixtures/files/searchable', "#{described_class.name.demodulize.underscore}.yaml")

  searches = YAML.safe_load_file(path, permitted_classes: [Symbol])
  searches.each do |search|
    it search[:name] do
      found = search[:entities][:found].map do |h|
        FactoryBot.create(h.delete(:factory), **h)
      end
      search[:entities][:not_found].map do |h|
        FactoryBot.create(h.delete(:factory), **h)
      end

      get :index, params: { filter: search[:query] }

      expect(response_body_data).to match_array(found.map { |item| hash_including('id' => item.id) })
    end
  end
end
