# frozen_string_literal: true

require 'test_helper'

class ValueDefinitionTest < ActiveSupport::TestCase
  should belong_to(:benchmark)
  should validate_presence_of :ref_id
  should validate_uniqueness_of(:ref_id).scoped_to(:benchmark_id)
  should validate_presence_of(:value_type)
  should validate_presence_of(:description)

  setup do
    @value_definition = FactoryBot.create(:value_definition)
  end

  test 'does not allow to create record with invalid type' do
    assert_raises ActiveRecord::RecordInvalid do
      ValueDefinition.create!(
        ref_id: 'foo',
        title: 'faa',
        description: 'fuu',
        value_type: 'wrong',
        benchmark: @value_definition.benchmark
      )
    end
  end
end
