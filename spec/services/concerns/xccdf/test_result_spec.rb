# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::TestResult do
  subject(:service) do
    Class.new do
      include Xccdf::TestResult

      def initialize(system:, tailoring:, op_test_result:, security_guide:, op_rule_results:)
        @system = system
        @tailoring = tailoring
        @op_test_result = op_test_result
        @security_guide = security_guide
        @op_rule_results = op_rule_results
      end

      attr_reader :tailoring, :security_guide

      def selected_op_rule_results
        @op_rule_results
      end
    end.new(
      system: system,
      tailoring: tailoring,
      op_test_result: op_test_result,
      security_guide: security_guide,
      op_rule_results: op_rule_results
    )
  end

  let(:user) { create(:user) }
  let(:policy) { create(:policy, account: user.account, supports_minors: [0]) }
  let(:system) { create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0) }
  let(:tailoring) { Tailoring.find_by!(policy_id: policy.id, os_minor_version: 0) }
  let(:security_guide) { tailoring.security_guide }
  let(:op_rule_results) { [] }
  let(:op_test_result) do
    double(:op_test_result,
           score: 90.0,
           start_time: 5.minutes.ago,
           end_time: 1.minute.ago)
  end

  before do
    allow(SupportedSsg).to receive(:supported?).and_return(true)
  end

  describe '#save_test_result' do
    it 'creates a test result with the parsed attributes' do
      result = service.save_test_result

      expect(result).to be_persisted
      expect(result.system).to eq(system)
      expect(result.tailoring).to eq(tailoring)
      expect(result.score).to eq(90.0)
      expect(result.supported).to be true
    end

    context 'when a previous test result already exists for the same policy and system' do
      let!(:old_test_result) { create(:test_result, system: system, report_id: policy.id) }

      it 'replaces it with the new one' do
        expect { service.save_test_result }.not_to change(TestResult, :count)
        expect(TestResult.exists?(old_test_result.id)).to be false
      end
    end
  end

  describe '#supported?' do
    it 'delegates to SupportedSsg with the security guide version and system OS versions' do
      service.supported?

      expect(SupportedSsg).to have_received(:supported?).with(
        ssg_version: security_guide.version,
        os_major_version: system.os_major_version,
        os_minor_version: system.os_minor_version
      )
    end
  end
end
