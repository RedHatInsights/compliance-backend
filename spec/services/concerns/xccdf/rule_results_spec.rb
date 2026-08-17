# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::RuleResults do
  subject(:service) do
    Class.new do
      include Xccdf::RuleResults

      def initialize(test_result:, op_rule_results:, security_guide:, tailoring:, version_mismatched: false)
        @test_result = test_result
        @op_rule_results = op_rule_results
        @security_guide = security_guide
        @tailoring = tailoring
        @version_mismatched = version_mismatched
      end

      attr_reader :security_guide, :tailoring

      def version_mismatched?
        @version_mismatched
      end
    end.new(
      test_result: test_result,
      op_rule_results: op_rule_results,
      security_guide: security_guide,
      tailoring: tailoring,
      version_mismatched: version_mismatched
    )
  end

  let(:user) { create(:user) }
  let(:policy) { create(:policy, account: user.account, supports_minors: [0]) }
  let(:system) { create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0) }
  let(:test_result) { create(:test_result, system: system, report_id: policy.id) }
  let(:tailoring) { test_result.tailoring }
  let(:security_guide) { tailoring.security_guide }
  let(:rule) { create(:rule, security_guide: security_guide) }
  let(:version_mismatched) { false }

  let(:op_rule_results) do
    [
      OpenStruct.new(id: rule.ref_id, result: 'fail'),
      OpenStruct.new(id: Faker::Alphanumeric.alphanumeric(number: 16), result: 'pass')
    ]
  end

  describe '#selected_op_rule_results' do
    let(:op_rule_results) do
      not_selected = RuleResult::NOT_SELECTED.map do |result|
        OpenStruct.new(id: Faker::Alphanumeric.alphanumeric, result: result)
      end
      not_selected + [
        OpenStruct.new(id: Faker::Alphanumeric.alphanumeric, result: 'pass'),
        OpenStruct.new(id: Faker::Alphanumeric.alphanumeric, result: 'fail')
      ]
    end

    it 'excludes NOT_SELECTED results' do
      expect(service.selected_op_rule_results.map(&:result)).to contain_exactly('pass', 'fail')
    end
  end

  describe '#test_result_rules_unknown' do
    it 'returns rule IDs present in the report but absent from the security guide' do
      unknown_id = op_rule_results.last.id

      expect(service.test_result_rules_unknown).to contain_exactly(unknown_id)
    end

    context 'when all rule IDs are known' do
      let(:op_rule_results) { [OpenStruct.new(id: rule.ref_id, result: 'fail')] }

      it 'returns an empty array' do
        expect(service.test_result_rules_unknown).to be_empty
      end
    end
  end

  describe '#rule_results' do
    it 'builds a RuleResult for each selected op rule result' do
      results = service.rule_results

      expect(results.length).to eq(op_rule_results.length)
      expect(results).to all(be_a(RuleResult))
      expect(results).to all(have_attributes(test_result_id: test_result.id))
    end

    it 'maps rule IDs from the security guide for known rules' do
      result = service.rule_results.find { |rr| rr.rule_id == rule.id }

      expect(result).not_to be_nil
    end
  end

  describe '#save_rule_results' do
    it 'persists only results whose rule ID is known, skipping unknown entries' do
      expect { service.save_rule_results }
        .to change(RuleResult, :count).by(1)
    end
  end

  context 'when version is mismatched' do
    let(:version_mismatched) { true }
    let(:other_security_guide) { create(:security_guide) }
    let(:security_guide) { other_security_guide }
    let(:tailoring_guide) { tailoring.security_guide }
    let(:matched_rule) { create(:rule, security_guide: tailoring_guide) }
    let(:unmatched_ref_id) { Faker::Alphanumeric.alphanumeric(number: 16) }

    let(:op_rule_results) do
      [
        OpenStruct.new(id: matched_rule.ref_id, result: 'fail'),
        OpenStruct.new(id: unmatched_ref_id, result: 'pass')
      ]
    end

    describe '#rule_results' do
      it 'resolves rules against the tailoring security guide' do
        matched = service.rule_results.find { |rr| rr.rule_id == matched_rule.id }

        expect(matched).not_to be_nil
      end
    end

    describe '#save_rule_results' do
      it 'persists only results matching the tailoring security guide' do
        expect { service.save_rule_results }
          .to change(RuleResult, :count).by(1)
      end
    end

    describe '#test_result_rules_unknown' do
      it 'reports unmatched rules as unknown' do
        expect(service.test_result_rules_unknown).to contain_exactly(unmatched_ref_id)
      end
    end
  end

  describe '#failed_rules' do
    let!(:failed_rule_result) do
      create(:rule_result, test_result: test_result, rule: rule, result: 'fail')
    end

    it 'returns rules whose results are failed' do
      expect(service.failed_rules).to include(rule)
    end
  end
end
