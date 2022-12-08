# frozen_string_literal: true

require 'test_helper'

class XccdfTailoringFileTest < ActiveSupport::TestCase
  setup do
    @account = FactoryBot.create(:account)
    @parent = FactoryBot.create(:canonical_profile, :with_rules)
  end

  test 'builds a valid tailoring file' do
    profile = FactoryBot.create(:profile, :with_rules, account: @account)
    # profile.parent_profile = profile
    tailoring_file = XccdfTailoringFile.new(profile: profile)
    op_tailoring = OpenscapParser::TailoringFile.new(tailoring_file.to_xml)
                                                .tailoring
    assert_equal 'xccdf_csfr-compliance_tailoring_default', op_tailoring.id
    assert_equal [profile.ref_id],
                 op_tailoring.profiles.map(&:id)
    assert_equal profile.benchmark.ref_id,
                 op_tailoring.at_xpath('benchmark')[:id]
    assert_equal '1', op_tailoring.version
    assert DateTime.parse(op_tailoring.version_time) < DateTime.now,
           'Invalid date in tailoring file'
  end

  test 'handles empty rule_ref_ids and set_values' do
    profile = Profile.create!(
      ref_id: 'test',
      name: 'test profile',
      benchmark_id: @parent.benchmark.id,
      parent_profile_id: @parent.id
    )
    tailoring_file = XccdfTailoringFile.new(profile: profile)
    op_tailoring = OpenscapParser::TailoringFile.new(tailoring_file.to_xml)
                                                .tailoring
    assert_empty op_tailoring.profiles.first.selected_rule_ids
    assert_empty op_tailoring.profiles.first.xpath('set-value')
  end

  context 'compliance' do
    setup do
      profile = Profile.create!(
        ref_id: 'test',
        name: 'test profile',
        benchmark_id: @parent.benchmark.id,
        parent_profile_id: @parent.id
      )
      @rules = @parent.rules.take(2)

      @rule_group1 = FactoryBot.create(:rule_group)
      @rule_group2 = FactoryBot.create(:rule_group)
      @rule_group3 = FactoryBot.create(:rule_group)
      @rule_group4 = FactoryBot.create(:rule_group)

      @value1 = FactoryBot.create(:value_definition)
      @value2 = FactoryBot.create(:value_definition)
      @value3 = FactoryBot.create(:value_definition)

      @parent.benchmark.update!(rules: @rules)

      tailoring_file = XccdfTailoringFile.new(
        profile: profile,
        rule_ref_ids: {
          @rules.first.ref_id => false,
          @rules.last.ref_id => true
        },
        set_values: {
          @value1.ref_id => 'testing',
          @value2.ref_id => true,
          @value3.ref_id => 3
        },
        rule_group_ref_ids: [@rule_group1.ref_id, @rule_group2.ref_id, @rule_group3.ref_id, @rule_group4.ref_id]
      )
      @op_tailoring = OpenscapParser::TailoringFile.new(tailoring_file.to_xml)
                                                   .tailoring
    end
    should 'properly (de)selects rule_ref_ids' do
      assert_equal(
        @op_tailoring.profiles.first.selected_rule_ids,
        [@rules.last.ref_id]
      )

      assert_equal(
        @op_tailoring.profiles.first.xpath(
          "select[@selected='false']/@idref"
        ).text,
        @rules.first.ref_id
      )
    end

    should 'properly selects rule_group ref_ids' do
      assert_includes(
        @op_tailoring.profiles.first.xpath(
          "select[@selected='true']/@idref"
        ).text,
        @rule_group1.ref_id
      )
      assert_includes(
        @op_tailoring.profiles.first.xpath(
          "select[@selected='true']/@idref"
        ).text,
        @rule_group2.ref_id
      )
      assert_includes(
        @op_tailoring.profiles.first.xpath(
          "select[@selected='true']/@idref"
        ).text,
        @rule_group3.ref_id
      )
      assert_includes(
        @op_tailoring.profiles.first.xpath(
          "select[@selected='true']/@idref"
        ).text,
        @rule_group4.ref_id
      )
      assert_equal(
        @op_tailoring.profiles.first.xpath(
          "select[@selected='true']/@idref"
        ).length,
        5
      )
    end

    should 'properly overrides values with set-value' do
      assert_includes(
        @op_tailoring.profiles.first.xpath(
          'set-value/@idref'
        ).text,
        @value1.ref_id
      )

      assert_includes(
        @op_tailoring.profiles.first.xpath(
          'set-value'
        )[0].text,
        'testing'
      )

      assert_includes(
        @op_tailoring.profiles.first.xpath(
          'set-value/@idref'
        ).text,
        @value2.ref_id
      )

      assert_includes(
        @op_tailoring.profiles.first.xpath(
          'set-value'
        )[1].text,
        'true'
      )

      assert_includes(
        @op_tailoring.profiles.first.xpath(
          'set-value/@idref'
        ).text,
        @value3.ref_id
      )

      assert_includes(
        @op_tailoring.profiles.first.xpath(
          'set-value'
        )[2].text,
        '3'
      )

      assert_equal(
        @op_tailoring.profiles.first.xpath(
          'set-value'
        ).length,
        3
      )
    end
  end

  test 'handles missing rules in the benchmark' do
    profile = Profile.create!(
      ref_id: 'test',
      name: 'test profile',
      benchmark_id: @parent.benchmark.id,
      parent_profile_id: @parent.id
    )
    assert_raises(ArgumentError) do
      XccdfTailoringFile.new(profile: profile,
                             rule_ref_ids: { 'foo' => true }).to_xml
    end
  end

  test 'handles nil parent_profile' do
    assert_raises(ArgumentError) do
      XccdfTailoringFile.new(profile: OpenStruct.new).to_xml
    end
  end
end
