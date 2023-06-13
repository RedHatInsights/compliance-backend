# frozen_string_literal: true

require 'test_helper'

# A class to test the SsgConfigDownloader service
class ConfigDownloaderTest < ActiveSupport::TestCase
  context 'fallback file' do
    setup do
      FileUtils.rm_f(SsgConfigDownloader::DS_FILE_PATH)

      FileUtils.rm_f(SsgConfigDownloader::AT_FILE_PATH)

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
      @ds_config_file = ::Tempfile.new('ds_config_file')
      @ds_config_file.write(File.read(SsgConfigDownloader::DS_FALLBACK_PATH))
      @ds_config_file.rewind

      @at_config_file = ::Tempfile.new('at_config_file')
      @at_config_file.write(File.read(SsgConfigDownloader::AT_FALLBACK_PATH))
      @at_config_file.rewind
    end

    should 'ssg_ds returns SSG datastream file from disk' do
      SsgConfigDownloader.stub_const(:DS_FILE_PATH, @ds_config_file.path) do
        assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
      end
    end

    should 'ssg_ansible_tasks returns SSG ansible tasks file from disk' do
      SsgConfigDownloader.stub_const(:AT_FILE_PATH, @at_config_file.path) do
        assert_equal @at_config_file.read, SsgConfigDownloader.ssg_ansible_tasks
      end
    end

    should 'ssg_ds_checksum' do
      SsgConfigDownloader.stub_const(:DS_FILE_PATH, @ds_config_file.path) do
        assert_equal Digest::MD5.file(@ds_config_file).hexdigest,
                     SsgConfigDownloader.ssg_ds_checksum
      end
    end

    should 'ssg_ansible_tasks_checksum' do
      SsgConfigDownloader.stub_const(:AT_FILE_PATH, @at_config_file.path) do
        assert_equal Digest::MD5.file(@at_config_file).hexdigest,
                     SsgConfigDownloader.ssg_ansible_tasks_checksum
      end
    end

    should 'update_ssg_ds success' do
      SsgConfigDownloader.stub_const(:DS_FILE_PATH, @ds_config_file.path) do
        SafeDownloader.expects(:download)

        assert_audited_success 'Downloaded config'
        SsgConfigDownloader.update_ssg_ds

        assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
      end
    end

    should 'update_ssg_ansible_tasks success' do
      SsgConfigDownloader.stub_const(:AT_FILE_PATH, @at_config_file.path) do
        SafeDownloader.expects(:download)

        assert_audited_success 'Downloaded config'
        SsgConfigDownloader.update_ssg_ansible_tasks

        assert_equal @at_config_file.read, SsgConfigDownloader.ssg_ansible_tasks
      end
    end

    should 'update_ssg_ds handles failure gracefully' do
      SsgConfigDownloader.stub_const(:DS_FILE_PATH, @ds_config_file.path) do
        SafeDownloader.expects(:download).raises(StandardError)

        assert_audited_fail 'Failed to download config'
        SsgConfigDownloader.update_ssg_ds

        assert_equal @ds_config_file.read, SsgConfigDownloader.ssg_ds
      end
    end

    should 'update_ssg_ansible_tasks handles failure gracefully' do
      SsgConfigDownloader.stub_const(:AT_FILE_PATH, @at_config_file.path) do
        SafeDownloader.expects(:download).raises(StandardError)

        assert_audited_fail 'Failed to download config'
        SsgConfigDownloader.update_ssg_ansible_tasks

        assert_equal @at_config_file.read, SsgConfigDownloader.ssg_ansible_tasks
      end
    end

    teardown do
      @ds_config_file.close
      @ds_config_file.unlink
      @at_config_file.close
      @ds_config_file.unlink
    end
  end
end
