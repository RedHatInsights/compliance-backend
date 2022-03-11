# frozen_string_literal: true

require 'test_helper'

# A class to test downloading playbooks from compliance-ssg
class PlaybookDownloaderTest < ActiveSupport::TestCase
  setup do
    @profile = FactoryBot.create(:canonical_profile)
    @rule = FactoryBot.create(:rule)
    @rules = FactoryBot.create_list(:rule, 2)
    SafeDownloader.stubs(:download).returns(StringIO.new([{ name: @rule.short_ref_id }].to_json))
  end

  test 'playbook_exists? when it exists' do
    PlaybookDownloader.instance_variable_set(:@cache, nil)
    assert PlaybookDownloader.playbook_exists?(@rule)
  end

  test 'playbook_exists? when not exists' do
    PlaybookDownloader.instance_variable_set(:@cache, nil)
    assert_not PlaybookDownloader.playbook_exists?(@rules.sample)
  end

  test 'playbooks_exist?' do
    PlaybookDownloader.expects(:playbook_exists?).with(@rules[0]).returns(true)
    PlaybookDownloader.expects(:playbook_exists?).with(@rules[1]).returns(false)

    assert_equal({ @rules[0].id => true, @rules[1].id => false },
                 PlaybookDownloader.playbooks_exist?(@rules))
  end
end
