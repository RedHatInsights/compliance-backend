# frozen_string_literal: true

require 'test_helper'
require 'rake'

class ImportDatastreamTest < ActiveSupport::TestCase
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
end
