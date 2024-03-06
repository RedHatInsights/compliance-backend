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
#     :except_parents: [:parent] # skip the test if specified parents are present
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
# let(:extra_params) { { security_guide_id: 123, profile_id: 456 } }
#
# it_behaves_like 'sortable', :security_guide, :profile
# ```
#
# In a non-nested case the let block should contain an empty hash and the `parents` parameter
# should be empty, like so:
# ```
# let(:extra_params) { {} }
#
# it_behaves_like 'sortable'
# ```
#
# In some cases, however, additional ActiveRecord objects are required for invoking a factory.
# Therefore, if you don't want these objects to be passed to the `params` of the request, you
# can specify them in the `extra_params` as objects (i.e. without the `_id` suffix):
# ```
# let(:extra_params) { { account: FactoryBot.create(:v2_account) } }
#
# it_behaves_like 'sortable'
# ```
#
RSpec.shared_examples 'sortable' do |*parents|
  let(:passable_params) do
    extra_params.reject { |_, ep| ep.is_a?(ActiveRecord::Base) }
  end

  path = Rails.root.join('spec/fixtures/files/sortable', "#{described_class.name.demodulize.underscore}.yaml")
  tests = YAML.safe_load_file(path, permitted_classes: [Symbol])

  let(:items) do
    tests[:entities].map do |entity|
      entity = factory_params(entity, extra_params)
      FactoryBot.create(entity.delete(:factory), **entity)
    end
  end

  tests[:queries].each do |test_case|
    {
      # Default behavior
      test_case[:sort_by] => test_case[:result],

      # Explicitly specified directions
      test_case[:sort_by].map do |sort|
        field, direction = sort.split(':')
        direction ||= 'asc'
        [field, direction].join(':')
      end => test_case[:result],

      # Reverse behavior
      test_case[:sort_by].map do |sort|
        field, direction = sort.split(':')
        direction = direction == 'desc' ? nil : 'desc'
        [field, direction].compact.join(':')
      end => test_case[:result].reverse,

      # Explicitly specified directions but reversed
      test_case[:sort_by].map do |sort|
        field, direction = sort.split(':')
        direction = direction == 'desc' ? 'asc' : 'desc'
        [field, direction].join(':')
      end => test_case[:result].reverse

    }.each do |sort_by, ordered|
      next if parents.to_a.intersect?(test_case[:except_parents].to_a)

      it "sorts by #{sort_by.join(', ')}" do
        result = ordered.flat_map do |item|
          if item.is_a?(Array)
            item.map { |index| items[index].id }.sort
          else
            items[item].id
          end
        end

        get :index, params: passable_params.merge(sort_by: sort_by, parents: parents)

        # Only run the normalized expectation if the sorting did not match
        if response_body_data.map { |item| item['id'] } != result
          expect(
            response_body_data.map { |item| items.index { |record| record.id == item['id'] } }
          ).to eq(ordered)
        end

        expect(response_body_data.map { |item| item['id'] }).to eq(result)
      end
    end
  end
end
