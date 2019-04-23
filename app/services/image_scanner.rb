# frozen_string_literal: true

class ImageScanner
  def initialize(imagestream, profile, b64_identity)
    @imagestream = imagestream
    @profile = profile
    @b64_identity = b64_identity
    @image_name = imagestream.name
    @registry_url = imagestream.openshift_connection.registry_api_url
    @namespace, @image_name = image_name.split('/')
  end

  def parse_job
    ParseReportJob.perform_later(
      File.read(report_filepath),
      @imagestream.openshift_connection.account.account_number,
      @b64_identity
    )
  end

  def download_image
    Docker.authenticate!(
      'username' => @imagestream.openshift_connection.username,
      'password' => @imagestream.openshift_connection.token,
      'serveraddress' => @registry_url
    )
    Docker::Image.create(
      'fromImage' => "#{@registry_url}/#{@namespace}/#{@image_name}:latest"
    )
  end

  def report_filepath
    "#{@registry_url}-#{@namespace}-#{@image_name}-#{@profile}-results.xml"
  end

  def run_oscap_docker
    policy = '/usr/share/xml/scap/ssg/content/ssg-rhel7-xccdf.xml'
    cmd = TTY::Command.new
    out, err = cmd.run(
      "sudo oscap-docker image #{@registry_url}/#{@namespace}/"\
      "#{image_name}:latest xccdf eval --fetch-remote-resources"\
      " --results #{report_filepath} --profile #{@profile} #{policy}"
    )
    Sidekiq.logger.error("Error running oscap-docker: #{err}")
    Sidekiq.logger.info("Output from oscap-docker: #{out}")
  end
end
