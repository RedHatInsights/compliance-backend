# frozen_string_literal: true

# Module to fetch info related to the current pod running
module OpenshiftEnvironment
  class << self
    def environment
      ENV['SETTINGS__PROMETHEUS_EXPORTER_HOST'].split('.')[1]
    end

    def application
      ENV['APPLICATION_TYPE']
    end

    def pod
      ENV['HOSTNAME']
    end

    def build
      ENV['OPENSHIFT_BUILD_NAME']
    end

    def namespace
      ENV['NAMESPACE']
    end

    def summary
      {
        environment: environment,
        application: application,
        pod: pod,
        build: build,
        namespace: namespace
      }
    end
  end
end
