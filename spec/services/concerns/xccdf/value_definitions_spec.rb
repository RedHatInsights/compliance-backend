# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::ValueDefinitions do
  subject(:service) do
    Class.new do
      include Xccdf::ValueDefinitions

      def initialize(security_guide:, op_value_definitions:)
        @security_guide = security_guide
        @op_value_definitions = op_value_definitions
      end
    end.new(security_guide: security_guide, op_value_definitions: op_value_definitions)
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide) }

  let(:op_value_to_update) do
    OpenStruct.new(
      id: 'xccdf_value_password_complexity',
      title: 'Password complexity',
      description: 'Updated description',
      type: 'string',
      default_value: 'strict',
      overrides: { 'moderate' => 'medium' }
    ).tap do |op|
      def op.value(selector = nil)
        selector ? overrides.fetch(selector, selector) : default_value
      end
    end
  end

  let(:new_op_value) do
    OpenStruct.new(
      id: 'xccdf_value_selinux_state',
      title: 'SELinux state',
      description: 'Enable SELinux',
      type: 'string',
      default_value: 'enforcing',
      overrides: {}
    ).tap do |op|
      def op.value(selector = nil)
        selector ? overrides.fetch(selector, selector) : default_value
      end
    end
  end

  let(:op_value_definitions) { [op_value_to_update, new_op_value] }

  let!(:existing_definition) do
    FactoryBot.create(:v2_value_definition,
                      security_guide: security_guide,
                      ref_id: op_value_to_update.id,
                      description: 'stale description',
                      default_value: 'permissive')
  end

  describe '#save_value_definitions' do
    before { service.save_value_definitions }

    it 'updates existing definitions with the parser attributes' do
      expect(existing_definition.reload.description).to eq(op_value_to_update.description)
      expect(existing_definition.default_value).to eq(op_value_to_update.value)
    end

    it 'creates missing definitions for the guide' do
      created = V2::ValueDefinition.find_by(ref_id: new_op_value.id, security_guide: security_guide)

      expect(created).not_to be_nil
      expect(created.title).to eq(new_op_value.title)
      expect(created.default_value).to eq(new_op_value.default_value)
    end
  end
end
