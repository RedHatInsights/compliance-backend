# frozen_string_literal: true

require 'test_helper'

class XccdfTailoringFileTest < ActiveSupport::TestCase
  test 'builds a valid tailoring file' do
    profile = profiles(:one)
    profile.parent_profile = profile
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
      benchmark_id: profiles(:one).benchmark.id,
      parent_profile_id: profiles(:one).id
    )
    tailoring_file = XccdfTailoringFile.new(profile: profile)
    op_tailoring = OpenscapParser::TailoringFile.new(tailoring_file.to_xml)
                                                .tailoring
    assert_empty op_tailoring.profiles.first.selected_rule_ids
    assert_empty op_tailoring.profiles.first.xpath('set-value')
  end

  test 'properly (de)selects rule_ref_ids' do
    profile = Profile.create!(
      ref_id: 'test',
      name: 'test profile',
      benchmark_id: profiles(:one).benchmark.id,
      parent_profile_id: profiles(:one).id
    )
    profiles(:one).benchmark.update!(rules: [rules(:one), rules(:two)])
    tailoring_file = XccdfTailoringFile.new(
      profile: profile,
      rule_ref_ids: {
        rules(:one).ref_id => false,
        rules(:two).ref_id => true
      }
    )
    op_tailoring = OpenscapParser::TailoringFile.new(tailoring_file.to_xml)
                                                .tailoring
    assert_equal(
      op_tailoring.profiles.first.selected_rule_ids,
      [rules(:two).ref_id]
    )

    assert_equal(
      op_tailoring.profiles.first.xpath(
        "select[@selected='false']/@idref"
      ).text,
      rules(:one).ref_id
    )
  end

  test 'handles missing rules in the benchmark' do
    profile = Profile.create!(
      ref_id: 'test',
      name: 'test profile',
      benchmark_id: profiles(:one).benchmark.id,
      parent_profile_id: profiles(:one).id
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
