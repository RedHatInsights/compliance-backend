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

    context 'when the existing data differs from the op data' do
      before do
        allow(service).to receive(:security_guide_contents_equal_to_op?).and_return(false)
      end

      it 'runs the pipeline' do
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
    end

    context 'when the existing data matches the op data' do
      before do
        allow(service).to receive(:security_guide_contents_equal_to_op?).and_return(true)
      end

      it 'short-circuits' do
        service.save_all_security_guide_info

        expect(service).not_to have_received(:save_security_guide)
        expect(service).not_to have_received(:save_value_definitions)
        expect(service).not_to have_received(:save_profiles)
        expect(service).not_to have_received(:save_rule_groups)
        expect(service).not_to have_received(:save_rules)
        expect(service).not_to have_received(:save_fixes)
        expect(service).not_to have_received(:save_profile_rules)
        expect(service).not_to have_received(:save_profile_os_minor_versions)
      end
    end
  end
end
