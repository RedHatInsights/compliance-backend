# frozen_string_literal: true

require 'rails_helper'

describe V2::RuleGroup do
  describe '.from_parser' do
    let(:security_guide) { FactoryBot.create(:v2_security_guide) }
    let(:parent_group) { FactoryBot.create(:v2_rule_group, security_guide: security_guide) }

    let(:precedence) { 5 }
    let(:parser_obj) do
      OpenStruct.new(
        id: "xccdf_org.ssgproject.content_rule_group_#{SecureRandom.hex}",
        title: Faker::Lorem.sentence,
        description: Faker::Lorem.paragraph,
        rationale: Faker::Lorem.paragraph
      )
    end

    context 'creating a new record' do
      subject do
        described_class.from_parser(
          parser_obj,
          security_guide_id: security_guide.id,
          parent_id: parent_group.id,
          precedence: 5
        )
      end

      it 'sets attributes from parser object' do
        expect(subject.attributes.slice(
                 'ref_id', 'security_guide_id', 'title', 'description', 'rationale', 'precedence', 'ancestry'
               )).to eq(
                 'ref_id' => parser_obj.id,
                 'security_guide_id' => security_guide.id,
                 'title' => parser_obj.title,
                 'description' => parser_obj.description,
                 'rationale' => parser_obj.rationale,
                 'precedence' => precedence,
                 'ancestry' => parent_group.id
               )

        expect(subject).not_to be_persisted
      end
    end

    context 'updating an existing record' do
      let(:existing) { FactoryBot.create(:v2_rule_group, security_guide: security_guide) }

      subject do
        described_class.from_parser(
          parser_obj,
          existing: existing,
          security_guide_id: security_guide.id,
          parent_id: parent_group.id,
          precedence: precedence
        )
      end

      it 'only updates the fields necessary' do
        expect(subject.id).to eq(existing.id)
        expect(subject.has_changes_to_save?).to be_truthy

        expect(subject.attributes.slice('title', 'description', 'rationale', 'precedence', 'ancestry')).to eq(
          'title' => parser_obj.title,
          'description' => parser_obj.description,
          'rationale' => parser_obj.rationale,
          'precedence' => precedence,
          'ancestry' => parent_group.id
        )
      end
    end
  end
end
