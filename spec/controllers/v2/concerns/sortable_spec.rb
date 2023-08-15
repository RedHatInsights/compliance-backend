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
#  e.g.: expected order is 0, 1, 2, 3, but 2 and 3 need to be sorted by FactoryBot ID (sorted property is same for both)
#     => written as [0, 1, [2, 3]]
#
# parents - array of parental ActiveRecord models
#         - usage: it_behaves_like 'sortable', Parent1, Parent2
# extra_params - extra parameters to be passed into request
#              - usage:
#                 it_behaves_like 'sortable', parents do
#                   let(:extra_params) { { *extra parameters* } }
#                 end

RSpec.shared_examples 'sortable' do |*parents|
  path = Rails.root.join('spec/fixtures/files/sortable', "#{described_class.name.demodulize.underscore}.yaml")
  tests = YAML.safe_load_file(path, permitted_classes: [Symbol])

  let(:items) do
    tests[:entities].map do |entity|
      entity = factory_params(entity, extra_params)
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

      nested_route(*parents) do |mocked_parents|
        get :index, params: extra_params.merge(sort_by: test_case[:sort_by], parents: mocked_parents)
      end
      expect(response_body_data.map { |item| item['id'] }).to eq(result)
    end
  end
end
