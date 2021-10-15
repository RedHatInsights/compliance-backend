# frozen_string_literal: true

require 'test_helper'

# A class to test the SsgConfigDownloader service
class ConfigDownloaderTest < ActiveSupport::TestCase
  context 'fallback file' do
    setup do
      if File.exist?(SsgConfigDownloader::DS_FILE_PATH)
        File.delete(SsgConfigDownloader::DS_FILE_PATH)
      end

      if File.exist?(SsgConfigDownloader::AT_FILE_PATH)
        File.delete(SsgConfigDownloader::AT_FILE_PATH)
      end

      @ds_config_file = File.new(SsgConfigDownloader::DS_FALLBACK_PATH)
      @at_config_file = File.new(SsgConfigDownloader::AT_FALLBACK_PATH)
    end

    should 'ssg_ds returns SSG datastream fallback file from disk' do
      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    should 'ssg_ansible_tasks returns SSG datastream fallback file from disk' do
      assert_equal @at_config_file.read, SsgConfigDownloader.ssg_ansible_tasks
    end

    should 'ssg_ds_checksum' do
      assert_equal Digest::MD5.file(@ds_config_file).hexdigest,
                   SsgConfigDownloader.ssg_ds_checksum
    end

    should 'ssg_ansible_tasks_checksum' do
      assert_equal Digest::MD5.file(@at_config_file).hexdigest,
                   SsgConfigDownloader.ssg_ansible_tasks_checksum
    end
  end

  context 'downloaded file' do
    setup do
      FileUtils.cp(
        SsgConfigDownloader::DS_FALLBACK_PATH,
        SsgConfigDownloader::DS_FILE_PATH
      )

      FileUtils.cp(
        SsgConfigDownloader::AT_FALLBACK_PATH,
        SsgConfigDownloader::AT_FILE_PATH
      )

      @ds_config_file = File.new(SsgConfigDownloader::DS_FILE_PATH)
      @at_config_file = File.new(SsgConfigDownloader::AT_FILE_PATH)
    end

    should 'ssg_ds returns SSG datastream file from disk' do
      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    should 'ssg_ansible_tasks returns SSG ansible tasks file from disk' do
      assert_equal @at_config_file.read, SsgConfigDownloader.ssg_ansible_tasks
    end

    should 'ssg_ds_checksum' do
      assert_equal Digest::MD5.file(@ds_config_file).hexdigest,
                   SsgConfigDownloader.ssg_ds_checksum
    end

    should 'ssg_ansible_tasks_checksum' do
      assert_equal Digest::MD5.file(@at_config_file).hexdigest,
                   SsgConfigDownloader.ssg_ansible_tasks_checksum
    end

    should 'update_ssg_ds success' do
      SafeDownloader.expects(:download)

      SsgConfigDownloader.update_ssg_ds
      assert_audited 'Downloaded config'

      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    should 'update_ssg_ansible_tasks success' do
      SafeDownloader.expects(:download)

      SsgConfigDownloader.update_ssg_ansible_tasks
      assert_audited 'Downloaded config'

      assert_equal @at_config_file.read, SsgConfigDownloader.ssg_ansible_tasks
    end

    should 'update_ssg_ds handles failure gracefully' do
      SafeDownloader.expects(:download).raises(StandardError)

      SsgConfigDownloader.update_ssg_ds
      assert_audited 'Failed to download config'

      assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
    end

    should 'update_ssg_ansible_tasks handles failure gracefully' do
      SafeDownloader.expects(:download).raises(StandardError)

      SsgConfigDownloader.update_ssg_ansible_tasks
      assert_audited 'Failed to download config'

      assert_equal @at_config_file.read, SsgConfigDownloader.ssg_ansible_tasks
    end

    teardown do
      if File.exist?(SsgConfigDownloader::DS_FILE_PATH)
        File.delete(SsgConfigDownloader::DS_FILE_PATH)
      end

      if File.exist?(SsgConfigDownloader::AT_FILE_PATH)
        File.delete(SsgConfigDownloader::AT_FILE_PATH)
      end
    end
  end
end
