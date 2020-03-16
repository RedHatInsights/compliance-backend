# frozen_string_literal: true

require 'test_helper'

class RuleTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:ref_id).scoped_to(:benchmark_id)
  should validate_presence_of :ref_id

  setup do
    fake_report = file_fixture('xccdf_report.xml').read
    @op_rules = OpenscapParser::TestResultFile.new(fake_report).benchmark.rules
  end

  test 'creates rules from openscap_parser Rule object' do
    assert Rule.from_openscap_parser(@op_rules.first,
                                     benchmark_id: benchmarks(:one).id).save
  end

  test 'host one is not compliant?' do
    assert_not rules(:one).compliant?(hosts(:one), rules(:one).profiles.first)
  end

  test 'host one is compliant?' do
    rules(:one).profiles << profiles(:one)
    rule_results(:one).update(host: hosts(:one), rule: rules(:one))
    test_result = TestResult.create(profile: profiles(:one), host: hosts(:one),
                                    end_time: DateTime.now)
    test_result.rule_results << rule_results(:one)
    assert rules(:one).compliant?(hosts(:one), profiles(:one))
  end

  test 'rule is found with_references' do
    rules(:one).update(rule_references: [rule_references(:one)])
    assert Rule.with_references(rule_references(:one).label)
               .include?(rules(:one)),
           'Expected rule not found by references'
  end

  test 'rule is found with_identifier' do
    rules(:one).update(rule_identifier: rule_identifiers(:one))
    assert Rule.with_identifier(rule_identifiers(:one).label)
               .include?(rules(:one)),
           'Expected rule not found by identifier'
  end

  test 'rule is identified properly as canonical' do
    assert_not rules(:one).canonical?,
               'Rule :one should not be canonical to start'
    rules(:one).profiles << Profile.create!(
      ref_id: 'foo', name: 'foo', benchmark: benchmarks(:one)
    )
    assert rules(:one).canonical?, 'Rule :one should be canonical'
  end

  test 'canonical rules are found via canonical scope' do
    assert_empty Rule.canonical, 'No canonical rules should exist'
    rules(:one).profiles << Profile.create!(
      ref_id: 'foo', name: 'foo', benchmark: benchmarks(:one)
    )
    assert_equal [rules(:one)], Rule.canonical
  end
end
