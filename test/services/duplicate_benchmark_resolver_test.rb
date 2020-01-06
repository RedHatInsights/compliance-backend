# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20200106134953_add_unique_index_to_benchmarks'

class DuplicateBenchmarkResolverTest < ActiveSupport::TestCase
  setup do
    @migration = AddUniqueIndexToBenchmarks.new
    @migration.down # remove db constraint

    (@dupe_bm = benchmarks(:one).dup).save(validate: false)

    @dupe_rules = rules.map do |r|
      dupe_r = r.dup
      dupe_r.benchmark = @dupe_bm
      dupe_r.save(validate: false)
      dupe_r
    end

    @dupe_profiles = profiles.map do |p|
      dupe_p = p.dup
      dupe_p.benchmark = @dupe_bm
      dupe_p.rules = [@dupe_rules.first]
      dupe_p.save(validate: false)
      dupe_p
    end

    @dupe_test_results = test_results.map do |tr|
      dupe_tr = tr.dup
      dupe_tr.save(validate: false)
      dupe_tr
    end

    @dupe_rule_results = rule_results.map do |rr|
      dupe_rr = rr.dup
      dupe_rr.test_result = @dupe_test_results.sample
      dupe_rr
    end
  end

  test 'resolves identical benchmarks' do
    assert_difference(
      'Xccdf::Benchmark.count' => -1,
      'Profile.count' => -2,
      'Rule.count' => -2,
      'RuleResult.count' => 0,
      'TestResult.count' => 0,
      'RuleReference.count' => 0,
      'Host.count' => 0,
      'ProfileHost.count' => 0
    ) do
      @migration.up
    end
  end
end
