# frozen_string_literal: true

require 'test_helper'

class ShortRefIdTest < ActiveSupport::TestCase
  class RefIdMock
    attr_accessor :ref_id
    include ShortRefId
  end

  setup do
    @mock = RefIdMock.new
  end

  test 'shortens profile ref_ids' do
    @mock.ref_id = 'xccdf_org.ssgproject.content_profile_CSCF-RHEL6-MLS'

    assert_equal 'cscf-rhel6-mls', @mock.short_ref_id
  end

  test 'shortens rule ref_ids' do
    @mock.ref_id = 'xccdf_org.ssgproject.content_rule_banner_etc_issue'

    assert_equal 'banner_etc_issue', @mock.short_ref_id
  end
end
