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

  test 'ssg:sync_supported calls the SupportedSsgUpdater' do
    SupportedSsgUpdater.expects(:run!)
    capture_io do
      Rake::Task['ssg:sync_supported'].execute
    end
  end

  test 'ssg:import imports the file' do
    ENV['DATASTREAM_FILE'] = 'test/fixtures/files/xccdf_report.xml'
    DatastreamImporter.any_instance.expects(:import!)

    capture_io do
      Rake::Task['ssg:import'].execute
    end
  end

  test 'ssg:import propagates errors further' do
    ENV['DATASTREAM_FILE'] = 'foo'

    assert_raises(StandardError) do
      capture_io do
        Rake::Task['ssg:import'].execute
      end
    end
  end

  test 'ssg:check_synced fails if datastreams are not synced' do
    SupportedSsg.expects(:revision).at_least_once.returns('2021-07-15')
    Revision.expects(:datastreams).at_least_once.returns('2021-06-01')

    assert_raises(SystemExit, 'SSG datastreams not synced') do
      capture_io do
        Rake::Task['ssg:check_synced'].execute
      end
    end
  end

  test 'ssg:check_synced fails if remediations are not synced' do
    SupportedSsg.expects(:revision).at_least_once.returns('2021-07-15')
    SupportedRemediations.expects(:revision).at_least_once.returns('2021-07-15')
    Revision.expects(:datastreams).at_least_once.returns('2021-07-15')
    Revision.expects(:remediations).at_least_once.returns('2021-06-01')

    assert_raises(SystemExit, 'SSG remediations not synced') do
      capture_io do
        Rake::Task['ssg:check_synced'].execute
      end
    end
  end

  test 'ssg:check_synced succeeds if datastreams and remediations are synced' do
    SupportedSsg.expects(:revision).at_least_once.returns('2021-07-15')
    SupportedRemediations.expects(:revision).at_least_once.returns('2021-07-15')
    Revision.expects(:remediations).at_least_once.returns('2021-07-15')
    Revision.expects(:datastreams).at_least_once.returns('2021-07-15')

    assert_nothing_raised do
      capture_io do
        Rake::Task['ssg:check_synced'].execute
      end
    end
  end

  test 'ssg:check_synced succeeds if datastreams and remediations are synced but have different revision dates' do
    SupportedSsg.expects(:revision).at_least_once.returns('2021-07-15')
    SupportedRemediations.expects(:revision).at_least_once.returns('2021-06-11')
    Revision.expects(:remediations).at_least_once.returns('2021-06-11')
    Revision.expects(:datastreams).at_least_once.returns('2021-07-15')

    assert_nothing_raised do
      capture_io do
        Rake::Task['ssg:check_synced'].execute
      end
    end
  end
end
