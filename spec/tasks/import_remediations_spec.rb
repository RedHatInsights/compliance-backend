# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'import_remediations task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  describe 'import_remediations' do
    let(:current_date) { Time.zone.now.to_date.to_s }
    let(:old_time) { 1.day.ago.to_date.to_s }
    let(:ansible_yaml) { { 'revision' => current_date }.to_yaml }

    before do
      allow(SsgConfigDownloader).to receive(:update_ssg_ansible_tasks)
      allow(SsgConfigDownloader).to receive(:ssg_ansible_tasks).and_return(ansible_yaml)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    context 'when remediations are not synced' do
      let!(:rules_with_playbooks) { FactoryBot.create_list(:v2_rule, 5, remediation_available: false) }
      let!(:rules_without_playbooks) { FactoryBot.create_list(:v2_rule, 5, remediation_available: true) }
      let(:playbook_status_by_rule_id) do
        result = {}
        rules_with_playbooks.each { |rule| result[rule.id] = true }
        rules_without_playbooks.each { |rule| result[rule.id] = false }
        result
      end

      before do
        remediations_revision = old_time
        allow(Revision).to receive(:remediations) { remediations_revision }
        allow(Revision).to receive(:remediations=) { |val| remediations_revision = val }
        allow(PlaybookDownloader).to receive(:playbooks_exist?).and_return(playbook_status_by_rule_id)
      end

      it 'syncs remediations and updates rules' do
        Rake::Task['import_remediations'].execute

        expect(Revision).to have_received(:remediations=).with(current_date)
        expect(Rails.logger).to have_received(:info).with(
          "Updated #{rules_with_playbooks.count} rules with remediations"
        )
        expect(Rails.logger).to have_received(:info).with(
          "Updated #{rules_without_playbooks.count} rules without remediations"
        )
        expect(Rails.logger).to have_received(:info).with("Remediations synced to revision: #{current_date}")

        rules_with_playbooks.each { |rule| expect(rule.reload.remediation_available).to be(true) }
        rules_without_playbooks.each { |rule| expect(rule.reload.remediation_available).to be(false) }
      end

      context 'when rsyslog_remote_loghost is in the list of rules' do
        let!(:excluded_rule) do
          FactoryBot.create(:v2_rule,
                            ref_id: 'xccdf_org.ssgproject.content_rule_rsyslog_remote_loghost',
                            remediation_available: true)
        end

        let(:playbook_status_by_rule_id) do
          result = {}
          rules_with_playbooks.each { |rule| result[rule.id] = true }
          rules_without_playbooks.each { |rule| result[rule.id] = false }
          result[excluded_rule.id] = true # Playbook exists but should be excluded
          result
        end

        it 'rsyslog_remote_loghost remediation is not imported' do
          Rake::Task['import_remediations'].execute

          expect(excluded_rule.reload.remediation_available).to be(false)
          rules_with_playbooks.each { |rule| expect(rule.reload.remediation_available).to be(true) }
          rules_without_playbooks.each { |rule| expect(rule.reload.remediation_available).to be(false) }
        end
      end
    end

    context 'when remediations are synced' do
      before do
        allow(Revision).to receive(:remediations).and_return(current_date)
      end

      it 'logs that remediations are already synced and does not update' do
        expect(PlaybookDownloader).not_to receive(:playbooks_exist?)

        Rake::Task['import_remediations'].execute

        expect(Rails.logger).to have_received(:info).with("Remediations synced to revision: #{current_date}")
      end
    end

    context 'when an error is raised' do
      before do
        allow(SsgConfigDownloader).to receive(:update_ssg_ansible_tasks).and_raise(StandardError, 'fail')
        allow(ExceptionNotifier).to receive(:notify_exception)
        allow(OpenshiftEnvironment).to receive(:summary).and_return({})
      end

      it 'propagates and logs errors' do
        expect { Rake::Task['import_remediations'].execute }.to raise_error(StandardError, 'fail')

        expect(Rails.logger).to have_received(:error).with(match(/import_remediations job failed/))
        expect(ExceptionNotifier).to have_received(:notify_exception)
      end
    end
  end
end
