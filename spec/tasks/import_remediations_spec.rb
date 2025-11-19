# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'import_remediations task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  describe 'import_remediations' do
    let(:current_date) { Time.now.to_date.to_s }
    let(:old_time) { (Time.now - 1.day).to_date.to_s }
    let(:ansible_yaml) { { 'revision' => current_date }.to_yaml }

    before do
      allow(SsgConfigDownloader).to receive(:update_ssg_ansible_tasks)
      allow(SsgConfigDownloader).to receive(:ssg_ansible_tasks).and_return(ansible_yaml)
    end

    context 'when remediations are not synced' do
      before do
        allow(Revision).to receive(:remediations).and_return(old_time)

        allow(PlaybookDownloader).to receive(:playbooks_exist?).and_return(playbook_status_by_rule_id)
        allow(Revision).to receive(:remediations=)
      end

      let(:rules_with_playbooks) { FactoryBot.create_list(:v2_rule, 5, remediation_available: true) }
      let(:rules_without_playbooks) { FactoryBot.create_list(:v2_rule, 5) }
      let(:rules) { rules_with_playbooks + rules_without_playbooks }
      let(:playbook_status_by_rule_id) {
        rules.each_with_object({}) do |rule, hash|
          hash[rule.id] = rule.remediation_available
        end
      }

      it 'syncs remediations and updates rules' do
        expect(rules_without_playbooks).to receive(:update_all).with(remediation_available: false)
        expect(rules_with_playbooks).to receive(:update_all).with(remediation_available: true)

        expect(Revision).to receive(:remediations=).with(current_date)

        expect(Rails.logger).to receive(:info).with("Updated #{rules_with_playbooks.count} rules with remediations")
        expect(Rails.logger).to receive(:info).with("Updated #{rules_without_playbooks.count} rules without remediations")
        expect(Rails.logger).to receive(:info).with("Remediations synced to revision: #{current_date}")
        expect(Rails.logger).to receive(:info).with(match(/Finishing import_remediations job at/))

        Rake::Task['import_remediations'].execute
      end

      context 'when rsyslog_remote_loghost is in the list of rules' do
        before do
          allow(PlaybookDownloader).to receive(:playbook_exists?).and_return(true)
        end

        let(:excluded_rule) { FactoryBot.create(:v2_rule,
          ref_id: 'xccdf_org.ssgproject.content_rule_rsyslog_remote_loghost',
          remediation_available: true
        )}
        let(:rules) { rules_without_playbooks + rules_with_playbooks + [excluded_rule] }

        it 'rsyslog_remote_loghost remediation is not imported' do
          expect(Rails.logger).to receive(:info).with("Updated #{rules_without_playbooks.count + excluded_rule.count} rules without remediations")
          expect(Rails.logger).to receive(:info).with("Updated #{rules_with_playbooks.count} rules with remediations")

          Rake::Task['import_remediations'].execute

          expect(excluded_rule.reload.remediation_available).to be(false)
          expect(rules_with_playbooks.reload.map(&:remediation_available)).to eq([true] * rules_with_playbooks.count)
          expect(rules_without_playbooks.reload.map(&:remediation_available)).to eq([false] * rules_without_playbooks.count)
        end
      end
    end

    context 'when remediations are synced' do
      before do
        allow(Revision).to receive(:remediations).and_return(current_date)
      end

      it 'logs that remediations are already synced and does not update' do
        expect(PlaybookDownloader).not_to receive(:playbooks_exist?)
        expect(Rails.logger).to receive(:info).with("Remediations synced to revision: #{current_date}")
        expect(Rails.logger).to receive(:info).with(match(/Finishing import_remediations job at/))

        Rake::Task['import_remediations'].execute
      end
    end

    context 'when an error is raised' do
      before do
        allow(SsgConfigDownloader).to receive(:update_ssg_ansible_tasks).and_raise(StandardError, 'fail')
        allow(ExceptionNotifier).to receive(:notify_exception)
        allow(OpenshiftEnvironment).to receive(:summary).and_return({})
      end

      it 'propagates and logs errors' do
        expect(Rails.logger).to receive(:error).with(match(/import_remediations job failed/))
        expect(ExceptionNotifier).to receive(:notify_exception)

        expect { Rake::Task['import_remediations'].execute }.to raise_error(StandardError, 'fail')
      end
    end
  end
end
