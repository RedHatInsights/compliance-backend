# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200417174948_add_unique_index_to_rule_references'
require 'sidekiq/testing'

class DuplicateRuleReferenceResolverTest < ActiveSupport::TestCase
  setup do
    # rubocop:disable Lint/SuppressedException
    begin
      ActiveRecord::Migration.suppress_messages do
        AddUniqueIndexToRuleReferences.new.down
      end
    rescue ArgumentError # if index doesn't exist
    end
    # rubocop:enable Lint/SuppressedException

    @rule_reference = FactoryBot.create(:rule_reference)

    assert_difference('RuleReference.count' => 1) do
      (@dup_reference = @rule_reference.dup).save(validate: false)
    end
  end

  test 'resolves identical references' do
    assert_difference('RuleReference.count' => -1) do
      DuplicateRuleReferenceResolver.run!
    end
  end

  test 'resolves identical rules of identical references' do
    rule = FactoryBot.create(:rule)
    assert_difference('RuleReferencesRule.count' => 2) do
      @rule_reference.rules << rule
      @dup_reference.rules << rule
    end

    assert_difference('RuleReferencesRule.count' => -1) do
      DuplicateRuleReferenceResolver.run!
    end
  end

  test 'resolves different rules of identical references' do
    assert_difference('RuleReferencesRule.count' => 2) do
      @rule_reference.rules << FactoryBot.create(:rule)
      @dup_reference.rules << FactoryBot.create(:rule)
    end

    assert_difference('RuleReferencesRule.count' => 0) do
      DuplicateRuleReferenceResolver.run!
    end
  end
end
