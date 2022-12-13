# frozen_string_literal: true

require 'test_helper'
require 'xccdf/value_definitions'

class ValueDefinitionsTest < ActiveSupport::TestCase
  include Xccdf::Profiles
  include Xccdf::ValueDefinitions
  include Xccdf::Rules
  include Xccdf::RuleGroups
  include Xccdf::ProfileRules
  include Xccdf::RuleReferencesContainers

  attr_accessor :benchmark, :account, :op_profiles, :op_value_definitions

  setup do
    account = FactoryBot.create(:account)
    FactoryBot.create(:host, org_id: account.org_id)
    @benchmark = FactoryBot.create(:canonical_profile).benchmark
    parser = OpenscapParser::TestResultFile.new(
      file_fixture('rhel-xccdf-report.xml').read
    )
    @op_rules = parser.benchmark.rules
    @op_rule_groups = parser.benchmark.groups
    @op_value_definitions = parser.benchmark.values
  end

  test 'save all value_definitions as new' do
    assert_difference('ValueDefinition.count', 408) do
      save_value_definitions
    end

    assert_no_difference('ValueDefinition.count') do
      save_value_definitions
    end
  end

  test 'updates value field when needed' do
    save_value_definitions

    value_def = @benchmark.value_definitions.find_by(ref_id: 'xccdf_org.ssgproject.content_value_var_mcelog_server')

    assert_equal value_def.default_value, 'false'

    @value_definitions = nil
    @old_value_definitions = nil
    @new_value_definitions = nil
    op_vd = @op_value_definitions.find { |t| t.id == 'xccdf_org.ssgproject.content_value_var_mcelog_server' }
    op_vd.stubs(:value).returns('true')

    save_value_definitions

    assert_equal value_def.reload[:default_value], 'true'
  end

  test 'updates description field when needed' do
    save_value_definitions

    @value_definitions = nil
    @old_value_definitions = nil
    @new_value_definitions = nil
    op_vd = @op_value_definitions.find { |t| t.id == 'xccdf_org.ssgproject.content_value_var_mcelog_server' }
    op_vd.instance_variable_set('@description'.to_sym, 'foobar')

    save_value_definitions

    after = @benchmark.value_definitions.find_by(ref_id: 'xccdf_org.ssgproject.content_value_var_mcelog_server')

    assert_equal after.description, 'foobar'
  end

  test 'correctly assigns all attributes' do
    save_value_definitions

    val = @value_definitions.find { |vd| vd.ref_id == 'xccdf_org.ssgproject.content_value_var_accounts_tmout' }

    assert_equal '600', val.default_value
    assert_equal 'number', val.value_type
  end
end
