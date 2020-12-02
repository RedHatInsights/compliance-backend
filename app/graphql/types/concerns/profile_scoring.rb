# frozen_string_literal: true

module Types
  # Methods related to profile scoring
  module ProfileScoring
    extend ActiveSupport::Concern

    def unsupported_host_count
      ::CollectionLoader.for(
        object.class,
        object.policy_id ? :policy_test_results : :test_results
      ).load(object).then do |test_results|
        test_results.latest.supported(false).count
      end
    end

    def compliant_host_count
      ::CollectionLoader.for(
        object.class,
        object.policy_id ? :policy_test_result_hosts : :test_result_hosts
      ).load(object).then do |hosts|
        hosts.count { |host| object.compliant?(host) }
      end
    end

    def total_host_count
      ::CollectionLoader.for(policy_or_report.class, :hosts)
                        .load(policy_or_report).then(&:count)
    end

    def test_result_host_count
      ::CollectionLoader.for(
        object.class,
        object.policy_id ? :policy_test_result_hosts : :test_result_hosts
      ).load(object).then(&:count)
    end
  end
end
