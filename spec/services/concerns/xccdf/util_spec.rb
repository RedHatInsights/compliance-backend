# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::Util do
  subject(:service) { Class.new { include Xccdf::Util }.new }

  describe '#save_all_security_guide_info' do
    before do
      allow(service).to receive(:save_security_guide)
      allow(service).to receive(:save_value_definitions)
      allow(service).to receive(:save_profiles)
      allow(service).to receive(:save_rule_groups)
      allow(service).to receive(:save_rules)
      allow(service).to receive(:save_fixes)
      allow(service).to receive(:save_profile_rules)
      allow(service).to receive(:save_profile_os_minor_versions)
    end

    it 'runs the pipeline when the existing data differs' do
      allow(service).to receive(:security_guide_contents_equal_to_op?).and_return(false)

      service.save_all_security_guide_info

      expect(service).to have_received(:save_security_guide)
      expect(service).to have_received(:save_value_definitions)
      expect(service).to have_received(:save_profiles)
      expect(service).to have_received(:save_rule_groups)
      expect(service).to have_received(:save_rules)
      expect(service).to have_received(:save_fixes)
      expect(service).to have_received(:save_profile_rules)
      expect(service).to have_received(:save_profile_os_minor_versions)
    end

    it 'short-circuits when the contents match' do
      allow(service).to receive(:security_guide_contents_equal_to_op?).and_return(true)

      service.save_all_security_guide_info

      expect(service).not_to have_received(:save_security_guide)
    end
  end

  describe '#save_all_test_result_info' do
    before do
      allow(service).to receive(:save_host_profile)
      allow(service).to receive(:save_test_result)
      allow(service).to receive(:save_rule_results)
      allow(service).to receive(:invalidate_cache)
    end

    it 'stores host profile, test result and rule results' do
      service.save_all_test_result_info

      expect(service).to have_received(:save_host_profile)
      expect(service).to have_received(:save_test_result)
      expect(service).to have_received(:save_rule_results)
      expect(service).to have_received(:invalidate_cache)
    end
  end

  describe '#set_openscap_parser_data' do
    let(:op_rule_groups) { [instance_double('OpRuleGroup')] }
    let(:op_profiles) { [instance_double('OpProfile')] }
    let(:op_values) { [instance_double('OpValue')] }
    let(:op_rules) { [instance_double('OpRule')] }
    let(:op_rule_results) { [instance_double('OpRuleResult')] }
    let(:op_benchmark) do
      instance_double('OpBenchmark', groups: op_rule_groups, profiles: op_profiles, values: op_values, rules: op_rules)
    end
    let(:op_test_result) { instance_double('OpTestResult', rule_results: op_rule_results) }
    let(:test_result_file) do
      instance_double('OpTestResultFile', benchmark: op_benchmark, test_result: op_test_result)
    end

    it 'caches rule, profile and value data extracted from the parser' do
      service.instance_variable_set(:@test_result_file, test_result_file)

      service.set_openscap_parser_data

      expect(service.instance_variable_get(:@op_benchmark)).to eq(op_benchmark)
      expect(service.instance_variable_get(:@op_test_result)).to eq(op_test_result)
      expect(service.instance_variable_get(:@op_rule_groups)).to eq(op_rule_groups)
      expect(service.instance_variable_get(:@op_profiles)).to eq(op_profiles)
      expect(service.instance_variable_get(:@op_value_definitions)).to eq(op_values)
      expect(service.instance_variable_get(:@op_rules)).to eq(op_rules)
      expect(service.instance_variable_get(:@op_rule_results)).to eq(op_rule_results)
    end
  end

  describe '#invalidate_cache' do
    let(:cache_store) { instance_double(ActiveSupport::Cache::Store) }
    let(:host_profile_rule) { instance_double('Rule', id: 'rule-1') }
    let(:host_profile) { instance_double('HostProfile', id: 'profile-1', rules: [host_profile_rule]) }
    let(:host) { instance_double('Host', id: 'host-1') }
    let(:new_host_profile) { instance_double('HostProfile', id: 'new-profile') }

    before do
      service.instance_variable_set(:@host_profile, host_profile)
      service.instance_variable_set(:@host, host)
      service.instance_variable_set(:@new_host_profile, new_host_profile)
      allow(Rails).to receive(:cache).and_return(cache_store)
      allow(cache_store).to receive(:delete)
    end

    it 'removes the cached summary and per-rule compliance entries' do
      service.send(:invalidate_cache)

      expect(cache_store).to have_received(:delete).with('new-profile/host-1/results')
      expect(cache_store).to have_received(:delete).with('rule-1/host-1/compliant')
    end
  end
end
