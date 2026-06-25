# frozen_string_literal: true

require 'rails_helper'

describe ParseReportJob, type: :job do
  subject(:job) { described_class.new }

  let(:user) { create(:v2_user) }
  let(:policy) { create(:v2_policy, account: user.account, supports_minors: [0], compliance_threshold: 80) }
  let(:system) { create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0) }
  let(:tailoring) { V2::Tailoring.find_by!(policy_id: policy.id, os_minor_version: 0) }
  let(:request_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
  let(:issue_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
  let(:msg_value) do
    {
      'id' => system.id,
      'org_id' => user.org_id,
      'request_id' => request_id,
      'url' => '',
      'account' => nil
    }
  end
  let(:profile_ref_id) { policy.profile.ref_id }
  let(:parser) { instance_double(XccdfReportParser) }
  let(:test_result_file) do
    double(:test_result_file, test_result: double(:test_result, profile_id: profile_ref_id))
  end
  before do
    allow(SafeDownloader).to receive(:download_reports)
      .with('', ssl_only: Settings.report_download_ssl_only)
      .and_return([Faker::Lorem.word])
    allow(job).to receive(:job_id).and_return('1')
    allow(XccdfReportParser).to receive(:new).and_return(parser)
    allow(parser).to receive(:test_result_file).and_return(test_result_file)
    allow(parser).to receive(:policy).and_return(policy)
    allow(parser).to receive(:system).and_return(system)
    allow(parser).to receive(:tailoring).and_return(tailoring)
    allow(parser).to receive(:supported?).and_return(true)
    # Score above threshold (80) prevents spurious notifications in non-notification tests
    allow(parser).to receive(:score).and_return(90)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:audit_success)
    allow(Rails.logger).to receive(:audit_fail)
  end

  describe '#perform' do
    context 'when parsing succeeds' do
      before do
        allow(parser).to receive(:save_all)
        allow(job).to receive(:remediation_issue_ids).and_return([issue_id])
        allow(PayloadTracker).to receive(:deliver)
        allow(RemediationUpdates).to receive(:deliver)
      end

      it 'notifies payload tracker about processing start and success' do
        expect(PayloadTracker).to receive(:deliver).with(
          account: nil, system_id: system.id,
          request_id: request_id, status: :processing,
          status_msg: 'Job 1 is now processing', org_id: user.org_id
        )
        expect(PayloadTracker).to receive(:deliver).with(
          account: nil, system_id: system.id,
          request_id: request_id, status: :success,
          status_msg: 'Job 1 has completed successfully', org_id: user.org_id
        )

        job.perform(0, msg_value)
      end

      it 'audits the successful report' do
        expect(Rails.logger).to receive(:audit_success).with(
          a_string_matching(
            /\A\[#{user.org_id}\] Successful report of #{profile_ref_id} policy #{policy.id} from system #{system.id}\z/
          )
        )

        job.perform(0, msg_value)
      end

      it 'notifies the remediation service with failed issue ids' do
        expect(RemediationUpdates).to receive(:deliver).with(
          system_id: system.id,
          issue_ids: [issue_id]
        )

        job.perform(0, msg_value)
      end
    end

    context 'when parsing fails with a known XccdfReportParser error' do
      before do
        allow(parser).to receive(:save_all).and_raise(
          XccdfReportParser::WrongFormatError, 'Wrong format or benchmark'
        )
        allow(PayloadTracker).to receive(:deliver)
        allow(ReportUploadFailed).to receive(:deliver)
      end

      it 'notifies payload tracker about processing start and error' do
        expect(PayloadTracker).to receive(:deliver).with(
          account: nil, system_id: system.id,
          request_id: request_id, status: :processing,
          status_msg: 'Job 1 is now processing', org_id: user.org_id
        )
        expect(PayloadTracker).to receive(:deliver).with(
          account: nil, system_id: system.id,
          request_id: request_id, status: :error,
          status_msg: a_string_matching(
            /Failed to parse report #{profile_ref_id} from system #{system.id}: XccdfReportParser::WrongFormatError/
          ), org_id: user.org_id
        )

        job.perform(0, msg_value)
      end

      it 'audits the failure' do
        expect(Rails.logger).to receive(:audit_fail).with(
          a_string_matching(/\[#{user.org_id}\] Failed to parse report #{profile_ref_id} from system #{system.id}/)
        )

        job.perform(0, msg_value)
      end

      context 'when the system is found' do
        it 'notifies ReportUploadFailed with the found system' do
          expect(ReportUploadFailed).to receive(:deliver).with(
            system: system,
            request_id: request_id,
            error: a_string_matching(
              /Failed to parse report #{profile_ref_id} from system #{system.id}: WrongFormatError/
            ),
            org_id: user.org_id
          )

          job.perform(0, msg_value)
        end
      end

      context 'when the system is not found' do
        let(:nonexistent_id) { Faker::Internet.uuid }
        let(:msg_value) { super().merge('id' => nonexistent_id) }

        it 'notifies ReportUploadFailed with a nil system' do
          expect(ReportUploadFailed).to receive(:deliver).with(
            system: nil,
            request_id: request_id,
            error: a_string_matching(
              /Failed to parse report #{profile_ref_id} from system #{nonexistent_id}: WrongFormatError/
            ),
            org_id: user.org_id
          )

          job.perform(0, msg_value)
        end
      end
    end

    context 'when XccdfReportParser cannot be instantiated' do
      before do
        allow(XccdfReportParser).to receive(:new).and_raise(XccdfReportParser::WrongFormatError)
        allow(PayloadTracker).to receive(:deliver)
        allow(ReportUploadFailed).to receive(:deliver)
      end

      it 'audits the failure without a profile id' do
        expect(Rails.logger).to receive(:audit_fail).with(
          a_string_matching(/\[#{user.org_id}\] Failed to parse report\s+from system #{system.id}/)
        )

        job.perform(0, msg_value)
      end
    end
  end

  describe 'non-compliance notifications' do
    before do
      allow(parser).to receive(:save_all)
      allow(parser).to receive(:score).and_return(70) # below threshold of 80
      allow(job).to receive(:notify_payload_tracker)
      allow(job).to receive(:notify_remediation)
      allow(job).to receive(:audit_success)
    end

    context 'when the policy has never been tested' do
      it 'emits a non-compliance notification' do
        expect(SystemNonCompliant).to receive(:deliver)

        job.perform(0, msg_value)
      end
    end

    context 'when compliance drops below the threshold' do
      let!(:previous_test_result) do
        create(:v2_test_result, system: system, report_id: policy.id, score_above: 80, score_below: 100)
      end

      it 'emits a non-compliance notification' do
        expect(SystemNonCompliant).to receive(:deliver)

        job.perform(0, msg_value)
      end
    end

    context 'when the system is not supported by the security guide' do
      before { allow(parser).to receive(:supported?).and_return(false) }

      it 'does not emit a non-compliance notification' do
        expect(SystemNonCompliant).not_to receive(:deliver)

        job.perform(0, msg_value)
      end
    end

    context 'when compliance was already below the threshold before the scan' do
      let!(:previous_test_result) do
        create(:v2_test_result, system: system, report_id: policy.id, score_above: 0, score_below: 79)
      end

      it 'does not emit a non-compliance notification' do
        expect(SystemNonCompliant).not_to receive(:deliver)

        job.perform(0, msg_value)
      end
    end

    context 'when the new score remains at or above the threshold' do
      let!(:previous_test_result) do
        create(:v2_test_result, system: system, report_id: policy.id, score_above: 90, score_below: 100)
      end

      before { allow(parser).to receive(:score).and_return(85) }

      it 'does not emit a non-compliance notification' do
        expect(SystemNonCompliant).not_to receive(:deliver)

        job.perform(0, msg_value)
      end
    end
  end
end
