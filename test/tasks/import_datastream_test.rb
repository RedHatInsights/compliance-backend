# frozen_string_literal: true

require 'test_helper'
require 'rake'

class ImportDatastreamTest < ActiveSupport::TestCase
  setup do
    HostInventoryApi.any_instance.stubs(:inventory_host).returns(
      'display_name' => 'foo',
      'os_major_version' => 7,
      'os_minor_version' => 5
    )
  end

  test 'ssg:import fails on error' do
    filepath = 'test/fixtures/files/xccdf_report.xml'

    ENV['DATASTREAM_FILE'] = filepath

    DatastreamImporter.any_instance.expects(:import!).raises(StandardError)

    assert_raises StandardError do
      Rake::Task['ssg:import'].execute
    end
  end
end
