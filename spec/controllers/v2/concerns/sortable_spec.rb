# frozen_string_literal: true

# --- How to use ---
# Create yaml with name matching tested controller in the following format:
# `spec/fixtures/files/sortable/tested_controler.yaml`
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
# The `parents` parameter is required when testing nested controllers, and it should contain
# an ordered list of reflection symbols similarly to how they are defined in the routes. It is
# also required to set the `extra_params` variable in a let block and pass all the parent IDs
# there as a hash. For example:
# ```
# it_behaves_like 'sortable', :security_guide, :profile do
#   let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
# end
# ```
#
# In a non-nested case this example can be simply included as:
# ```
# it_behaves_like 'sortable'
# ```
#
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

      get :index, params: extra_params.merge(sort_by: test_case[:sort_by], parents: parents)

      expect(response_body_data.map { |item| item['id'] }).to eq(result)
    end
  end
end
