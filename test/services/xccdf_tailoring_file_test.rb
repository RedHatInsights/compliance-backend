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

  test 'handles nil parent_profile' do
    assert_raises(ArgumentError) do
      XccdfTailoringFile.new(profile: OpenStruct.new).to_xml
    end
  end
end
