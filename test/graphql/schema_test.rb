# frozen_string_literal: true

require 'test_helper'

class SchemaTest < ActiveSupport::TestCase
  test 'printout is up to date' do
    current_defn = Schema.to_definition
    printout_defn = Rails.root.join('app/graphql/schema.graphql').read
    assert_equal(
      current_defn, printout_defn,
      'Update the printed schema with `bundle exec rake dump_schema`'
    )
  end
end
