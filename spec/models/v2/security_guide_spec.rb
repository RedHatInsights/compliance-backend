# frozen_string_literal: true

require 'rails_helper'

describe V2::SecurityGuide do
  subject { FactoryBot.create(:v2_security_guide, os_major_version: os_version) }

  describe 'os_major_version' do
    context 'single digit os_major_version' do
      let(:os_version) { 7 }

      it 'returns correct os_major_version' do
        expect(subject.os_major_version).to eq(os_version)
      end
    end

    context 'double digit os_major_version' do
      let(:os_version) { 15 }

      it 'returns correct os_major_version' do
        expect(subject.os_major_version).to eq(15)
      end
    end
  end

  describe 'rule_tree' do
    let(:os_version) { 8 }

    let(:g1) { FactoryBot.create(:v2_rule_group, security_guide: subject) }
    let(:g2) { FactoryBot.create(:v2_rule_group, security_guide: subject, ancestry: g1.id) }
    let(:g3) { FactoryBot.create(:v2_rule_group, security_guide: subject, ancestry: [g2.ancestry, g2.id].join('/')) }
    let(:g4) { FactoryBot.create(:v2_rule_group, security_guide: subject, ancestry: [g2.ancestry, g2.id].join('/')) }

    let(:r1) { FactoryBot.create(:v2_rule, rule_group: g1, security_guide: subject) }
    let(:r2) { FactoryBot.create(:v2_rule, rule_group: g1, security_guide: subject) }
    let(:r3) { FactoryBot.create(:v2_rule, rule_group: g2, security_guide: subject) }
    let(:r4) { FactoryBot.create(:v2_rule, rule_group: g3, security_guide: subject) }

    it 'returns with a hierarhical structure' do
      g3.id
      result = [
        {
          type: :rule_group,
          id: g1.id,
          children: [
            {
              type: :rule_group,
              id: g2.id,
              children: [
                {
                  type: :rule_group,
                  id: g3.id,
                  children: [
                    {
                      type: :rule,
                      id: r4.id
                    }
                  ]
                },
                {
                  type: :rule_group,
                  id: g4.id,
                  children: []
                },
                {
                  type: :rule,
                  id: r3.id
                }
              ]
            },
            {
              type: :rule,
              id: r1.id
            },
            {
              type: :rule,
              id: r2.id
            }
          ]
        }
      ]

      expect(subject.rule_tree).to eq(result)
    end
  end
end
