# frozen_string_literal: true

# A service class to merge duplicate TestResult objects
class DuplicateTestResultResolver
  class << self
    def run!
      @test_results = nil
      duplicate_test_results.find_each do |test_result|
        if existing_test_result(test_result)
          migrate_test_result(existing_test_result(test_result),
                              test_result)
        else
          self.existing_test_result = test_result
        end
      end
    end

    private

    def existing_test_result(test_result)
      test_results[[test_result.host_id, test_result.profile_id,
                    test_result.end_time]]
    end

    def existing_test_result=(test_result)
      test_results[[test_result.host_id, test_result.profile_id,
                    test_result.end_time]] = test_result
    end

    def test_results
      @test_results ||= {}
    end

    def duplicate_test_results
      TestResult.joins(
        "JOIN (#{grouped_nonunique_test_result_tuples.to_sql}) as tr on "\
        'test_results.host_id = tr.host_id AND '\
        'test_results.profile_id = tr.profile_id AND '\
        'test_results.end_time = tr.end_time'
      )
    end

    def grouped_nonunique_test_result_tuples
      TestResult.select(:host_id, :profile_id, :end_time)
                .group(:host_id, :profile_id, :end_time)
                .having('COUNT(id) > 1')
    end

    def migrate_test_result(existing_tr, duplicate_tr)
      migrate_rule_results(existing_tr, duplicate_tr)
      duplicate_tr.destroy
    end

    # rubocop:disable Rails/SkipsModelValidations
    def migrate_rule_results(existing_tr, duplicate_tr)
      duplicate_tr.rule_results.where.not(host_id: existing_tr.host_id).or(
        duplicate_tr.rule_results.where.not(
          rule_id: existing_tr.rule_results.select(:rule_id)
        )
      ).update_all(test_result_id: existing_tr.id)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
