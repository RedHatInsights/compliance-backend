# frozen_string_literal: true

# Module to fetch info related to the current pod running
module OpenshiftEnvironment
  class << self
    def environment
      namespace&.send(:[], /(eph|stage|perf|prod)/) || 'dev'
    end

    def application
      ENV.fetch('APPLICATION_TYPE', nil)
    end

    def pod
      ENV.fetch('HOSTNAME', nil)
    end

    def build
      ENV.fetch('IMAGE_TAG', nil)
    end

    def namespace
      ENV.fetch('NAMESPACE', nil)
    end

    def qe_account?(org_id)
      qe_accounts = ENV.fetch('QE_ACCOUNTS', nil)
      return 0 if qe_accounts.blank? || org_id.nil?

      org_id.scan(/^(#{qe_accounts})$/).size
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
