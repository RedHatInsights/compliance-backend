# frozen_string_literal: true

require 'test_helper'

module Xccdf
  # To test the Xccdf::Benchmark model
  class BenchmarkTest < ActiveSupport::TestCase
    context 'model' do
      setup { FactoryBot.create(:benchmark) }

      should validate_uniqueness_of(:ref_id).scoped_to(:version)
      should validate_presence_of :ref_id
      should validate_presence_of :version
    end

    should have_many(:profiles)
    should have_many(:rules)
    should have_many(:rule_groups)

    OP_BENCHMARK = OpenStruct.new(id: '1', version: 'v0.1.49',
                                  title: 'one', description: 'first')

    test 'builds a Benchmark from_openscap_parser OpenscapParser::Benchmark' do
      benchmark = Benchmark.from_openscap_parser(OP_BENCHMARK)
      assert_equal OP_BENCHMARK.id, benchmark.ref_id
      assert_equal OP_BENCHMARK.version, benchmark.version
      assert_equal OP_BENCHMARK.title, benchmark.title
      assert_equal OP_BENCHMARK.description, benchmark.description
      assert benchmark.save
      assert_equal benchmark.id, Benchmark.from_openscap_parser(OP_BENCHMARK).id
    end

    test 'inferred_os_major_version' do
      OP_BENCHMARK[:id] = 'xccdf_org.ssgproject.content_benchmark_RHEL-7'
      benchmark = Benchmark.from_openscap_parser(OP_BENCHMARK)

      assert_equal '7', benchmark.inferred_os_major_version
    end

    test 'including_profile' do
      account = FactoryBot.create(:user).account
      supported_ssg1 = SupportedSsg.new(version: '0.1.50',
                                        os_major_version: '7', os_minor_version: '1')
      SupportedSsg.stubs(:all).returns([supported_ssg1])
      bm1 = FactoryBot.create(
        :benchmark,
        version: supported_ssg1.version,
        os_major_version: '7'
      )
      policy = FactoryBot.create(:policy, account: account)
      profile = FactoryBot.create(:profile, account: account, policy: policy, benchmark: bm1)
      profile.parent_profile.update!(upstream: false)

      assert_includes Xccdf::Benchmark.including_profile(profile), bm1
    end

    context '#latest_supported_os_minor_versions' do
      setup do
        SupportedSsg.expects(:latest_map).returns(
          '7' => {
            '8' => SupportedSsg.new(version: '0.1.48'),
            '9' => SupportedSsg.new(version: '0.1.52')
          },
          '6' => {
            '9' => SupportedSsg.new(version: '0.1.32'),
            '10' => SupportedSsg.new(version: '0.1.32')
          }
        ).at_least_once
      end

      should 'should return list of latest support minor versions' do
        bm = Xccdf::Benchmark.new(ref_id: 'RHEL-7', version: '0.1.52',
                                  title: 'foo1', description: 'a')
        assert_equal '7', bm.os_major_version
        assert_equal ['9'], bm.latest_supported_os_minor_versions

        bm = Xccdf::Benchmark.new(ref_id: 'RHEL-6', version: '0.1.32',
                                  title: 'foo2', description: 'a')
        assert_equal '6', bm.os_major_version
        assert_equal %w[10 9], bm.latest_supported_os_minor_versions.sort
      end

      should 'should return empty list on unmatched entries' do
        bm = Xccdf::Benchmark.new(ref_id: 'RHEL-7', version: '0.0.0',
                                  title: 'foo1', description: 'a')
        assert_equal [], bm.latest_supported_os_minor_versions
      end
    end

    test 'return latest benchmarks for all ref_ids' do
      Xccdf::Benchmark.create(ref_id: 'rhel7', version: '0.1.40',
                              title: 'foo1', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel7', version: '0.1.41',
                              title: 'foo2', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel7', version: '0.2.0',
                              title: 'foo3', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel6', version: '0.1.42',
                              title: 'foo4', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel8', version: '0.2.2',
                              title: 'foo5', description: 'a')

      latest = Xccdf::Benchmark.latest
      assert latest.count == 3
      assert_equal %w[rhel6 rhel7 rhel8],
                   latest.map(&:ref_id).sort
      assert_equal %w[0.1.42 0.2.0 0.2.2],
                   latest.map(&:version).sort
    end

    test 'os_major_version scope' do
      bm61 = Xccdf::Benchmark.create!(
        ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
        version: '1', title: 'A', description: 'A'
      )
      bm62 = Xccdf::Benchmark.create!(
        ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
        version: '2', title: 'A', description: 'A'
      )
      bm7 = Xccdf::Benchmark.create!(
        ref_id: 'xccdf_org.ssgproject.benchmark_RHEL-7',
        version: '1', title: 'A', description: 'A'
      )
      bm8 = Xccdf::Benchmark.create!(
        ref_id: 'foo_bar.ssgproject.benchmark_RHEL-8',
        version: '1', title: 'A', description: 'A'
      )

      assert_equal Set.new(Xccdf::Benchmark.os_major_version(6).to_a),
                   Set.new([bm61, bm62])
      assert_equal Xccdf::Benchmark.os_major_version(7).to_a, [bm7]
      assert_equal Xccdf::Benchmark.os_major_version(8).to_a, [bm8]

      assert_equal Set.new(Xccdf::Benchmark.os_major_version(6, false).to_a),
                   Set.new([bm7, bm8])
    end

    test 'os_major_version scoped_search' do
      bm61 = Xccdf::Benchmark.create!(
        ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
        version: '1', title: 'A', description: 'A'
      )
      bm62 = Xccdf::Benchmark.create!(
        ref_id: 'foo_bar.ssgproject.benchmark_RHEL-6',
        version: '2', title: 'A', description: 'A'
      )
      bm7 = Xccdf::Benchmark.create!(
        ref_id: 'xccdf_org.ssgproject.benchmark_RHEL-7',
        version: '1', title: 'A', description: 'A'
      )
      bm8 = Xccdf::Benchmark.create!(
        ref_id: 'foo_bar.ssgproject.benchmark_RHEL-8',
        version: '1', title: 'A', description: 'A'
      )

      assert_equal(
        Set.new(Xccdf::Benchmark.search_for('os_major_version = 6').to_a),
        Set.new([bm61, bm62])
      )
      assert_equal Xccdf::Benchmark.search_for('os_major_version = 7').to_a,
                   [bm7]
      assert_equal Xccdf::Benchmark.search_for('os_major_version = 8').to_a,
                   [bm8]
      assert_equal(
        Set.new(Xccdf::Benchmark.search_for('os_major_version != 6').to_a),
        Set.new([bm7, bm8])
      )
    end

    context 'latest_supported_os_minor_versions' do
      setup do
        ref_prefix = 'foo_bar.ssgproject.benchmark_RHEL-'
        @rhel_6_ref = "#{ref_prefix}6"
        @rhel_7_ref = "#{ref_prefix}7"
        @rhel_8_ref = "#{ref_prefix}8"

        # RHEL 6
        Xccdf::Benchmark.create!(
          ref_id: @rhel_6_ref, version: '0.1.32', title: 'A', description: 'A'
        )
        Xccdf::Benchmark.create!(
          ref_id: @rhel_6_ref, version: '0.1.40', title: 'A', description: 'A'
        )
        # RHEL 7
        Xccdf::Benchmark.create!(
          ref_id: @rhel_7_ref, version: '0.1.40', title: 'A', description: 'A'
        )
        Xccdf::Benchmark.create!(
          ref_id: @rhel_7_ref, version: '0.1.50', title: 'A', description: 'A'
        )
        # RHEL 8
        Xccdf::Benchmark.create!(
          ref_id: @rhel_8_ref, version: '0.1.70', title: 'A', description: 'A'
        )

        SupportedSsg.expects(:latest_map).returns(
          '6' => {
            '8' => SupportedSsg.new(version: '0.1.32'),
            '9' => SupportedSsg.new(version: '0.1.32'),
            '10' => SupportedSsg.new(version: '0.1.40')
          },
          '7' => {
            '1' => SupportedSsg.new(version: '0.1.40'),
            '9' => SupportedSsg.new(version: '0.1.50')
          }
        ).at_least_once
      end

      should 'scope all supported minor versions' do
        result = Xccdf::Benchmark.latest_supported_os_minor_versions('8')
        assert_equal 1, result.count
        assert_equal @rhel_6_ref, result.first.ref_id
        assert_equal '0.1.32', result.first.version

        result = Xccdf::Benchmark.latest_supported_os_minor_versions('9')
        assert_equal 2, result.count
        tuples = result.sort_by(&:version).map { |bm| [bm.ref_id, bm.version] }
        assert_equal [@rhel_6_ref, '0.1.32'], tuples[0]
        assert_equal [@rhel_7_ref, '0.1.50'], tuples[1]

        result = Xccdf::Benchmark.latest_supported_os_minor_versions('100')
        assert_equal 0, result.count
      end

      should 'scope supported minor versions for selected major version' do
        result = Xccdf::Benchmark.os_major_version('7')
                                 .latest_supported_os_minor_versions('9')
        assert_equal 1, result.count
        assert_equal @rhel_7_ref, result.first.ref_id
        assert_equal '0.1.50', result.first.version
      end

      should 'search by a supported minor version' do
        result = Xccdf::Benchmark.search_for(
          'latest_supported_os_minor_version = 8'
        )
        assert_equal 1, result.count
        assert_equal @rhel_6_ref, result.first.ref_id
        assert_equal '0.1.32', result.first.version

        result = Xccdf::Benchmark.search_for(
          'latest_supported_os_minor_version = 9'
        )
        assert_equal 2, result.count
        tuples = result.sort_by(&:version).map { |bm| [bm.ref_id, bm.version] }
        assert_equal [@rhel_6_ref, '0.1.32'], tuples[0]
        assert_equal [@rhel_7_ref, '0.1.50'], tuples[1]

        result = Xccdf::Benchmark.search_for(
          'latest_supported_os_minor_version = 100'
        )
        assert_equal 0, result.count
      end

      should 'search by a list of supported minor version' do
        result = Xccdf::Benchmark.search_for(
          'latest_supported_os_minor_version ^ (1, 100)'
        )
        assert_equal 1, result.count
        assert_equal @rhel_7_ref, result.first.ref_id
        assert_equal '0.1.40', result.first.version

        result = Xccdf::Benchmark.search_for(
          'latest_supported_os_minor_version ^ (1, 10)'
        )
        assert_equal 2, result.count
        tuples = result.sort_by(&:ref_id).map { |bm| [bm.ref_id, bm.version] }
        assert_equal [@rhel_6_ref, '0.1.40'], tuples[0]
        assert_equal [@rhel_7_ref, '0.1.40'], tuples[1]

        result = Xccdf::Benchmark.search_for(
          'latest_supported_os_minor_version ^ (8, 9)'
        )
        assert_equal 2, result.count
        tuples = result.sort_by(&:version).map { |bm| [bm.ref_id, bm.version] }
        assert_equal [@rhel_6_ref, '0.1.32'], tuples[0]
        assert_equal [@rhel_7_ref, '0.1.50'], tuples[1]

        result = Xccdf::Benchmark.search_for(
          'latest_supported_os_minor_version ^ (100, 200)'
        )
        assert_equal 0, result.count
      end

      should 'search by a list of supported minor version ' \
             ' for selected major version' do
        result = Xccdf::Benchmark.search_for(
          'os_major_version = 7' \
          ' and latest_supported_os_minor_version ^ (1, 100)'
        )
        assert_equal 1, result.count
        assert_equal @rhel_7_ref, result.first.ref_id
        assert_equal '0.1.40', result.first.version

        result = Xccdf::Benchmark.search_for(
          'os_major_version = 6 and latest_supported_os_minor_version = 9'
        )
        assert_equal 1, result.count
        assert_equal @rhel_6_ref, result.first.ref_id
        assert_equal '0.1.32', result.first.version

        result = Xccdf::Benchmark.search_for(
          'os_major_version = 6 and latest_supported_os_minor_version ^ (9, 10)'
        )
        assert_equal 2, result.count
        tuples = result.map { |bm| [bm.ref_id, bm.version] }
        assert_includes tuples, [@rhel_6_ref, '0.1.32']
        assert_includes tuples, [@rhel_6_ref, '0.1.40']
        assert_equal 2, tuples.count

        result = Xccdf::Benchmark.search_for(
          'os_major_version = 6 and latest_supported_os_minor_version ^ (8, 9)'
        )
        assert_equal 1, result.count
        assert_equal @rhel_6_ref, result.first.ref_id
        assert_equal '0.1.32', result.first.version

        result = Xccdf::Benchmark.search_for(
          'os_major_version = 8' \
          ' and latest_supported_os_minor_version ^ (1, 9, 10)'
        )
        assert_equal 0, result.count
      end
    end

    test 'order_by_version' do
      versions = ['9.0.0', '0.1.10', '0.1.1', '0.1.0']
      versions.shuffle.each do |version|
        FactoryBot.create(:benchmark, version: version)
      end

      benchmarks = Xccdf::Benchmark.order_by_version
      bm_versions = benchmarks.map(&:version)
      assert_equal versions.count, benchmarks.count
      assert_equal versions, bm_versions
    end

    context 'latest_for_os scope' do
      setup do
        @os_major_version = '7'
        @os_minor_version = '3'
        @ssg_versions = ['1.7.10', '1.7.1', '1.7.4']

        ssgs = @ssg_versions.map do |version|
          SupportedSsg.new(
            version: version,
            os_major_version: @os_major_version,
            os_minor_version: @os_minor_version
          )
        end

        FactoryBot.create(
          :benchmark,
          os_major_version: @os_major_version,
          version: '9.9.9'
        )

        SupportedSsg
          .expects(:for_os)
          .with(@os_major_version, @os_minor_version)
          .returns(ssgs)
      end

      should 'return the latest benchmark for supported SSG' do
        @ssg_versions.each do |version|
          FactoryBot.create(
            :benchmark,
            os_major_version: @os_major_version,
            version: version
          )
        end

        latest_for_os = Xccdf::Benchmark.latest_for_os(
          @os_major_version, @os_minor_version
        )
        assert_equal 1, latest_for_os.count
        assert_equal '1.7.10', latest_for_os.first.version
      end

      should 'fallback to previous existing' do
        FactoryBot.create(
          :benchmark,
          os_major_version: @os_major_version,
          version: '1.7.1'
        )
        bm = FactoryBot.create(
          :benchmark,
          os_major_version: @os_major_version,
          version: '1.7.4'
        )

        latest_for_os = Xccdf::Benchmark.latest_for_os(
          @os_major_version, @os_minor_version
        )
        assert_equal 1, latest_for_os.count
        assert_equal '1.7.4', latest_for_os.first.version
        assert_equal bm, latest_for_os.first
      end
    end

    context '#latest_supported' do
      setup do
        rhel6_supported = [
          SupportedSsg.new(
            version: '1.6.1', os_major_version: '6', os_minor_version: '10'
          )
        ]
        rhel7_supported = [
          SupportedSsg.new(
            version: '1.7.1', os_major_version: '7', os_minor_version: '3'
          ),
          SupportedSsg.new(
            version: '1.7.2', os_major_version: '7', os_minor_version: '9'
          ),
          SupportedSsg.new(
            version: '1.7.3', os_major_version: '7', os_minor_version: '9'
          )
        ]
        rhel8_supported = [
          SupportedSsg.new(
            version: '1.8.1', os_major_version: '8', os_minor_version: '1'
          ),
          SupportedSsg.new(
            version: '1.8.3', os_major_version: '8', os_minor_version: '4'
          ),
          SupportedSsg.new(
            version: '1.8.20', os_major_version: '8', os_minor_version: '3'
          )
        ]

        SupportedSsg
          .stubs(:by_os_major)
          .returns(
            '6' => rhel6_supported,
            '7' => rhel7_supported,
            '8' => rhel8_supported
          )
      end

      should 'return latest from extisting benchmarks' do
        bm6 = FactoryBot.create(
          :benchmark, os_major_version: '6', version: '1.6.1'
        )
        FactoryBot.create(:benchmark, os_major_version: '7', version: '1.7.1')
        FactoryBot.create(:benchmark, os_major_version: '7', version: '1.7.2')
        bm7 = FactoryBot.create(
          :benchmark, os_major_version: '7', version: '1.7.3'
        )
        FactoryBot.create(:benchmark, os_major_version: '8', version: '1.8.1')
        FactoryBot.create(:benchmark, os_major_version: '8', version: '1.8.3')
        bm8 = FactoryBot.create(
          :benchmark, os_major_version: '8', version: '1.8.20'
        )

        returned = Xccdf::Benchmark.latest_supported
        assert_includes returned, bm6
        assert_includes returned, bm7
        assert_includes returned, bm8
        assert_equal 3, returned.count
      end

      should 'fallbacks to previous existing benchmark' do
        FactoryBot.create(:benchmark, os_major_version: '7', version: '1.7.1')
        bm7 = FactoryBot.create(
          :benchmark, os_major_version: '7', version: '1.7.2'
        )

        returned = Xccdf::Benchmark.latest_supported
        assert_includes returned, bm7
        assert_equal 1, returned.count
      end
    end

    context 'rules_and_rule_groups' do
      setup do
        supported_ssg1 = SupportedSsg.new(version: '0.1.50',
                                          os_major_version: '7', os_minor_version: '1')
        SupportedSsg.stubs(:all).returns([supported_ssg1])
        @bm1 = FactoryBot.create(
          :benchmark,
          :with_rules,
          :with_rule_groups,
          version: supported_ssg1.version,
          os_major_version: '7',
          rule_count: 5,
          rule_group_count: 4
        )

        @rule1 = @bm1.rules.first
        @rule2 = @bm1.rules.second
        @rule3 = @bm1.rules.third
        @rule4 = @bm1.rules.fourth
        @rule5 = @bm1.rules.fifth
        @rule6 = FactoryBot.create(:rule)

        @rule_group_1 = @bm1.rule_groups.first
        @rule_group_2 = @bm1.rule_groups.second
        @rule_group_3 = @bm1.rule_groups.third
        @rule_group_4 = @bm1.rule_groups.fourth
        @rule_group_5 = FactoryBot.create(:rule_group)
        @rule_group_6 = FactoryBot.create(:rule_group)

        FactoryBot.create(:rule_group_rule, rule_id: @rule1.id, rule_group_id: @rule_group_1.id)
        FactoryBot.create(:rule_group_rule, rule_id: @rule2.id, rule_group_id: @rule_group_2.id)
        FactoryBot.create(:rule_group_rule, rule_id: @rule3.id, rule_group_id: @rule_group_3.id)
        FactoryBot.create(:rule_group_rule, rule_id: @rule5.id, rule_group_id: @rule_group_4.id)

        rgr1 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_conflicts)
        rgr2 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_conflicts)
        rgr3 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_requires)
        rgr4 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_requires)
        rgr5 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_conflicts)
        rgr6 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_conflicts)
        rgr7 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_conflicts)
        rgr8 = FactoryBot.create(:rule_group_relationship, :for_rule_and_rule_group_requires)

        rgr1.update!(left: @rule1, right: @rule_group_5)
        rgr2.update!(left: @rule_group_3, right: @rule_group_6)
        rgr3.update!(left: @rule4, right: @rule6)
        rgr4.update!(left: @rule1, right: @rule6)
        rgr5.update!(left: @rule_group_3, right: @rule6)
        rgr6.update!(left: @rule_group_4, right: @rule_group_6)
        rgr7.update!(left: @rule5, right: @rule6)
        rgr8.update!(left: @rule5, right: @rule_group_6)

        @rule_group_2.update!(parent_id: @rule_group_1.id)
        @rule_group_4.update!(parent_id: @rule_group_2.id)
      end

      should 'correctly return nested rule and rule group children of rule groups in JSON' do
        rules_and_rule_groups_json = @bm1.rule_tree

        expected_response1 = {
          rule_group: @rule_group_1,
          group_children: [
            {
              rule_group: @rule_group_2,
              group_children: [
                {
                  rule_group: @rule_group_4,
                  group_children: [],
                  rule_children: [
                    {
                      rule: @rule5,
                      requires: [@rule_group_6],
                      conflicts: [@rule6]
                    }
                  ],
                  requires: nil,
                  conflicts: [@rule_group_6]
                }
              ],
              rule_children: [
                {
                  rule: @rule2,
                  requires: nil,
                  conflicts: nil
                }
              ],
              requires: nil,
              conflicts: nil
            }
          ],
          rule_children: [
            {
              rule: @rule1,
              requires: [@rule6],
              conflicts: [@rule_group_5]
            }
          ],
          requires: nil,
          conflicts: nil
        }

        expected_response2 = {
          rule: @rule4,
          requires: [@rule6],
          conflicts: nil
        }

        expected_response3 = {
          rule_group: @rule_group_3,
          group_children: [],
          rule_children: [
            {
              rule: @rule3,
              requires: nil,
              conflicts: nil
            }
          ],
          requires: nil,
          conflicts: [@rule_group_6, @rule6]
        }

        expected_response4 = {
          rule_group: @rule_group_3,
          group_children: [],
          rule_children: [
            {
              rule: @rule3,
              requires: nil,
              conflicts: nil
            }
          ],
          requires: nil,
          conflicts: [@rule6, @rule_group_6]
        }

        assert_includes rules_and_rule_groups_json, expected_response1
        assert_includes rules_and_rule_groups_json, expected_response2
        assert rules_and_rule_groups_json.include?(expected_response3) ||
               rules_and_rule_groups_json.include?(expected_response4)
      end
    end
  end
end
