# frozen_string_literal: true

# Module to fetch info related to the current pod running
module OpenshiftEnvironment
  class << self
    def environment
      namespace&.send(:[], /(eph|stage|perf|prod)/) || 'dev'
    end

    def application
      ENV['APPLICATION_TYPE']
    end

    def pod
      ENV['HOSTNAME']
    end

    def build
      ENV['IMAGE_TAG']
    end

    def namespace
      ENV['NAMESPACE']
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
