# frozen_string_literal: true

require 'test_helper'
require 'rake'

class ImportDatastreamTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'ssg:import fails on error' do
    filepath = 'test/fixtures/files/xccdf_report.xml'

    ENV['DATASTREAM_FILE'] = filepath

    DatastreamImporter.any_instance.expects(:import!).raises(StandardError)

    assert_raises StandardError do
      capture_io do
        Rake::Task['ssg:import'].execute
      end
    end
  end

  test 'ssg:import_rhel_supported imports downstream datastreams' do
    Revision.stubs(:datastreams).returns('')
    DatastreamDownloader.any_instance
                        .expects(:download_datastreams)
                        .multiple_yields(['file1'], ['file2'])

    Rake::Task['ssg:import'].expects(:execute).with do
      ENV['DATASTREAM_FILE'] == 'file1'
    end
    Rake::Task['ssg:import'].expects(:execute).with do
      ENV['DATASTREAM_FILE'] == 'file2'
    end

    Rake::Task['import_remediations'].expects(:execute)

    capture_io do
      Rake::Task['ssg:import_rhel_supported'].execute
    end
  end

  test 'ssg:check_synced fails if datastreams are not synced' do
    SupportedSsg.expects(:revision).at_least_once.returns('2021-07-15')
    Revision.expects(:datastreams).at_least_once.returns('2021-06-01')

    assert_raises SystemExit do
      capture_io do
        Rake::Task['ssg:check_synced'].execute
      end
    end
  end

  test 'ssg:check_synced fails if remediations are not synced' do
    SupportedSsg.expects(:revision).at_least_once.returns('2021-07-15')
    Revision.expects(:datastreams).at_least_once.returns('2021-07-15')
    Revision.expects(:remediations).at_least_once.returns('2021-06-01')

    assert_raises SystemExit do
      capture_io do
        Rake::Task['ssg:check_synced'].execute
      end
    end
  end

  test 'ssg:check_synced succeeds if synced' do
    SupportedSsg.expects(:revision).at_least_once.returns('2021-07-15')
    Revision.expects(:remediations).at_least_once.returns('2021-07-15')
    Revision.expects(:datastreams).at_least_once.returns('2021-07-15')

    assert_nothing_raised do
      capture_io do
        Rake::Task['ssg:check_synced'].execute
      end
    end
  end
end
