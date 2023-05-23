# frozen_string_literal: true

# --- How to use ---
# Create yaml with name matching tested controller in the following format:
# `spec/controllers/v2/sort/tested_controler.yaml`
# ```yaml
# :entities:
#   - :factory: :name_of_your_factory
#     (fields passed to the factory)
#   - :factory: :name_of_your_factory
#     (fields passed to the factory)
# :queries:
#   - :sort_by:
#       - 'field to sort by with direction (e.g. name:asc, version:desc)'
#       - 'field to sort by with direction (e.g. name:asc, version:desc)'
#     :result: [1, 2, 3]
#   - :sort_by:
#       - 'field to sort by with direction (e.g. name:asc, version:desc)'
#       - 'field to sort by with direction (e.g. name:asc, version:desc)'
#     :result: [3, 2, 1]
# ```
# `:result` field is an array of indexes into entities array with expected order, nested arrays will be sorted by id

RSpec.shared_examples 'sortable' do
  path = File.join('spec/controllers/v2/sort', "#{described_class.name.demodulize.underscore}.yaml")
  tests = YAML.safe_load_file(path, permitted_classes: [Symbol])

  let(:items) do
    tests[:entities].map do |entity|
      entity = entity.dup
      FactoryBot.create(entity.delete(:factory), **entity)
    end
  end

  tests[:queries].each do |test_case|
    it "sorts by #{test_case[:sort_by].join(', ')}" do
      result = test_case[:result].flat_map do |item|
        if item.is_a?(Array)
          item.map { |index| items[index].id }.sort
        else
          items[item].id
        end
      end

      get :index, params: { sort_by: test_case[:sort_by] }

      expect(response_body_data.map { |item| item['id'] }).to eq(result)
    end
  end
end
