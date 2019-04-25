# frozen_string_literal: true

require 'test_helper'

class ImageScannerTest < ActiveSupport::TestCase
  setup do
    @imagestream = imagestreams(:one)
    @imagestream.openshift_connection = openshift_connections(:one)
    @imagestream.openshift_connection.account = accounts(:test)
    @profile = profiles(:one).ref_id
    @b64_identity = 'b64_id'
    @image_scanner = ImageScanner.new(@imagestream, @profile, @b64_identity)
  end

  test 'parse_job' do
    File.expects(:read).returns(:file)
    @image_scanner.expects(:report_filepath)
    ParseReportJob.expects(:perform_later)
                  .with(:file, accounts(:test).account_number, @b64_identity)
    @image_scanner.parse_job
  end

  test 'download_image' do
    Docker.expects(:authenticate!).with(
      'username' => openshift_connections(:one).username,
      'password' => openshift_connections(:one).token,
      'serveraddress' => openshift_connections(:one).registry_api_url
    )
    Docker::Image.expects(:create).with(
      'fromImage' => "#{openshift_connections(:one).registry_api_url}"\
      "/#{@imagestream.name}:latest"
    )
    @image_scanner.download_image
  end

  test 'report_filepath' do
    namespace, image_name = @imagestream.name.split('/')
    assert_equal "#{openshift_connections(:one).registry_api_url}-#{namespace}"\
      "-#{image_name}-#{@profile}-results.xml", @image_scanner.report_filepath
  end

  test 'run_scap_docker' do
    cmd = mock('TTY::Command')
    TTY::Command.expects(:new).returns(cmd)
    cmd.expects(:run)

    @image_scanner.run_oscap_docker
  end
end
