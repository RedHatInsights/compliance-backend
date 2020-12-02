# frozen_string_literal: true

module Types
  # Methods related to profile scoring
  module ProfileScoring
    extend ActiveSupport::Concern

    def unsupported_host_count
      ::CollectionLoader.for(
        object.class,
        test_result_method
      ).load(object).then do |test_results|
        test_results.latest.supported(false).count
      end
    end

    def compliant_host_count
      ::CollectionLoader.for(
        object.class,
        test_result_method
      ).load(object).then do |test_results|
        Host.where(id: test_results.latest.supported.select(:host_id))
            .count { |host| object.compliant?(host) }
      end
    end

    def total_host_count
      ::CollectionLoader.for(policy_or_report.class, :hosts)
                        .load(policy_or_report).then(&:count)
    end

    def test_result_host_count
      ::CollectionLoader.for(
        object.class,
        test_result_method
      ).load(object).then do |test_results|
        Host.where(id: test_results.latest.supported.select(:host_id)).count
      end
    end

    private

    def test_result_method
      object.policy_id ? :policy_test_results : :test_results
    end
  end
end
