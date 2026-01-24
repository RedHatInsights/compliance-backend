# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe Xccdf::ProfileRules do
  subject(:service) do
    Class.new do
      include Xccdf::ProfileRules

      def initialize(op_profiles:, profiles:, rules:, security_guide:)
        @op_profiles = op_profiles
        @profiles = profiles
        @rules = rules
        @security_guide = security_guide
      end
    end.new(
      op_profiles: op_profiles,
      profiles: profiles,
      rules: rules,
      security_guide: security_guide
    )
  end

  let(:security_guide) { FactoryBot.create(:v2_security_guide) }
  let(:profiles) { FactoryBot.create_list(:v2_profile, 2, security_guide: security_guide) }

  let!(:new_rules) { FactoryBot.create_list(:v2_rule, 2, security_guide: security_guide) }
  let(:rules) { [new_rules.first, new_rules.last, stale_rule] }

  let(:op_profiles) do
    [
      OpenStruct.new(id: profiles.first.ref_id, selected_rule_ids: [new_rules.first.ref_id, new_rules.last.ref_id]),
      OpenStruct.new(id: profiles.last.ref_id, selected_rule_ids: [new_rules.last.ref_id])
    ]
  end

  let!(:stale_rule) { FactoryBot.create(:v2_rule, security_guide: security_guide) }
  let!(:stale_link) { FactoryBot.create(:v2_profile_rule, profile: profiles.first, rule: stale_rule) }

  let(:profile_rule_count) { V2::ProfileRule.where(profile_id: profiles.map(&:id)).count }

  describe '#save_profile_rules' do
    let(:expected_pairs) do
      {
        profiles.first.id => [new_rules.first.id, new_rules.last.id],
        profiles.last.id => [new_rules.last.id]
      }
    end

    it 'upserts parsed profile-rule links' do
      expect do
        service.save_profile_rules
      end.to change {
        profile_rule_count
      }.from(1).to(expected_pairs.values.flatten.count)

      resulting_pairs = V2::ProfileRule.where(profile_id: profiles.map(&:id))
                                       .pluck(:profile_id, :rule_id)
                                       .group_by(&:first)
                                       .transform_values { |pairs| pairs.map(&:second).sort }

      expect(resulting_pairs).to eq(expected_pairs.transform_values(&:sort))
    end

    it 'removes all stale pairings' do
      service.save_profile_rules

      expect { stale_link.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when the import runs multiple times with the same data' do
      before do
        service.save_profile_rules
      end

      it 'saves records only once' do
        expect do
          service.save_profile_rules
        end.not_to(change { profile_rule_count })
      end
    end
  end
end
