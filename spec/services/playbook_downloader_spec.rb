# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlaybookDownloader do
  let(:os_major_version) { '7' }
  let(:short_ref_id) { 'xccdf_org.ssgproject.content_rule_foo' }
  let(:security_guide) { instance_double('SecurityGuide', os_major_version: os_major_version) }
  let(:rule) { instance_double('V2::Rule', id: 1, short_ref_id: short_ref_id, security_guide: security_guide) }
  let(:downloaded_file) { StringIO.new([{ 'name' => "#{short_ref_id}.yml" }].to_json) }

  before do
    allow(SafeDownloader).to receive(:download).and_return(downloaded_file)
    PlaybookDownloader.instance_variable_set(:@cache, nil)
  end

  describe '#playbook_exists?' do
    context 'when the playbook exists' do
      it 'returns true' do
        expect(PlaybookDownloader.playbook_exists?(rule)).to be true
      end
    end

    context 'when the playbook does not exist' do
      let(:other_rule) do
        instance_double('V2::Rule', id: 2, short_ref_id: 'other_rule', security_guide: security_guide)
      end

      it 'returns false' do
        expect(PlaybookDownloader.playbook_exists?(other_rule)).to be false
      end
    end
  end

  describe '#playbooks_exist?' do
    let(:rule1) { rule }
    let(:rule2) do
      instance_double('V2::Rule', id: 2, short_ref_id: 'missing_rule', security_guide: security_guide)
    end
    let(:rules) { [rule1, rule2] }

    it 'returns a hash of rule ids and playbook existence' do
      expect(PlaybookDownloader.playbooks_exist?(rules)).to eq(
        {
          rule1.id => true,
          rule2.id => false
        }
      )
    end
  end
end
