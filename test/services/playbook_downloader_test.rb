# frozen_string_literal: true

require 'test_helper'

# A class to test downloading playbooks from compliance-ssg
class PlaybookDownloaderTest < ActiveSupport::TestCase
  setup do
    @profile = FactoryBot.create(:canonical_profile)
    @rule = FactoryBot.create(:rule)
    @rules = FactoryBot.create_list(:rule, 2)
  end

  test 'playbook_exists? when it exists' do
    SafeDownloader.expects(:download).returns(:playbook)
    assert PlaybookDownloader.playbook_exists?(@rule)
    assert_audited 'Downloaded playbook'
  end

  test 'playbook_exists? specifying a profile_short_ref_id' do
    SafeDownloader.expects(:download).returns(:playbook)
    assert PlaybookDownloader.playbook_exists?(@rule, @profile)
    assert_audited 'Downloaded playbook'
  end

  test 'playbook_exists? handles download errors' do
    SafeDownloader.expects(:download).raises(StandardError)

    assert_nothing_raised do
      assert_not PlaybookDownloader.playbook_exists?(@rule)
    end
    assert_audited 'Failed to download playbook'
  end

  test 'playbooks_exist?' do
    PlaybookDownloader.expects(:playbook_exists?).with(@rules[0]).returns(true)
    PlaybookDownloader.expects(:playbook_exists?).with(@rules[1]).returns(false)

    assert_equal({ @rules[0].id => true, @rules[1].id => false },
                 PlaybookDownloader.playbooks_exist?(@rules))
  end
end
