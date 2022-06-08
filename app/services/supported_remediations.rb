# frozen_string_literal: true

require 'yaml'

# Service for Supported Remediations
class SupportedRemediations
  class << self
    def revision
      SsgConfigDownloader.update_ssg_ansible_tasks
      YAML.safe_load(SsgConfigDownloader.ssg_ansible_tasks)['revision']
    end
  end
end
