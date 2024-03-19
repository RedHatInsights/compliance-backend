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

    let(:g1) { FactoryBot.create(:v2_rule_group, security_guide: subject, precedence: 1) }
    let(:g2) { FactoryBot.create(:v2_rule_group, security_guide: subject, ancestry: g1.id, precedence: 2) }

    let(:g3) do
      FactoryBot.create(
        :v2_rule_group,
        security_guide: subject,
        ancestry: [g2.ancestry, g2.id].join('/'),
        precedence: 3
      )
    end

    let(:g4) do
      FactoryBot.create(
        :v2_rule_group,
        security_guide: subject,
        ancestry: [g2.ancestry, g2.id].join('/'),
        precedence: 4
      )
    end

    let(:r1) { FactoryBot.create(:v2_rule, rule_group: g1, security_guide: subject, precedence: 1) }
    let(:r2) { FactoryBot.create(:v2_rule, rule_group: g1, security_guide: subject, precedence: 2) }
    let(:r3) { FactoryBot.create(:v2_rule, rule_group: g2, security_guide: subject, precedence: 3) }
    let(:r4) { FactoryBot.create(:v2_rule, rule_group: g3, security_guide: subject, precedence: 4) }

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
