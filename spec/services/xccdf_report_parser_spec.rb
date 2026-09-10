# frozen_string_literal: true

require 'rails_helper'

# xccdf_report.xml uses benchmark xccdf_org.ssgproject.content_benchmark_RHEL-8 v0.1.40
# and profile xccdf_org.ssgproject.content_profile_standard
RSpec.describe XccdfReportParser do
  let(:user) { create(:user, :with_cert_auth) }
  let(:os_major_version) { 8 }
  let(:unsupported_os_major_version) { os_major_version - 1 }
  let(:system) { create(:system, account: user.account, os_major_version: os_major_version) }
  let(:report_contents) { file_fixture('xccdf_report.xml').read }
  let(:message) do
    { 'id' => system.id, 'b64_identity' => user.account.identity_header.raw }
  end
  let(:parser) { described_class.new(report_contents, message) }

  describe '#validate_message_format!' do
    context 'when id is missing' do
      let(:message) { { 'b64_identity' => user.account.identity_header.raw } }

      it 'raises MissingIdError' do
        expect { parser.validate_message_format! }.to raise_error(described_class::MissingIdError)
      end
    end

    context 'when b64_identity is missing' do
      let(:message) { { 'id' => system.id } }

      it 'raises MissingIdError' do
        expect { parser.validate_message_format! }.to raise_error(described_class::MissingIdError)
      end
    end
  end

  describe '#check_report_format' do
    context 'when the benchmark id does not start with the expected prefix' do
      before do
        allow(parser.test_result_file).to receive(:benchmark)
          .and_return(double(:benchmark, id: Faker::Lorem.word))
      end

      it 'raises WrongFormatError' do
        expect { parser.check_report_format }.to raise_error(described_class::WrongFormatError)
      end
    end
  end

  describe '#check_os_version' do
    context 'when the system OS major version does not match the security guide' do
      let(:system) { create(:system, account: user.account, os_major_version: unsupported_os_major_version) }

      it 'raises OSVersionMismatch' do
        expect { parser.check_os_version }.to raise_error(described_class::OSVersionMismatch)
      end
    end
  end

  describe '#check_for_external_reports' do
    context 'when no policy matches the report profile and system' do
      it 'raises ExternalReportError' do
        expect { parser.check_for_external_reports }
          .to raise_error(described_class::ExternalReportError)
      end
    end
  end

  describe '#check_for_missing_security_guide' do
    context 'when no matching security guide exists in the database' do
      it 'raises UnknownBenchmarkError' do
        expect { parser.check_for_missing_security_guide }
          .to raise_error(described_class::UnknownBenchmarkError)
      end
    end
  end

  describe '#check_for_missing_tailored_profile' do
    before { allow(parser).to receive(:tailored_profile).and_return(build(:profile)) }

    context 'when no matching profile exists in the database' do
      it 'raises UnknownProfileError' do
        expect { parser.check_for_missing_tailored_profile }
          .to raise_error(described_class::UnknownProfileError)
      end
    end
  end

  describe '#check_for_missing_rules' do
    before do
      allow(parser).to receive(:test_result_rules_unknown)
        .and_return([Faker::Alphanumeric.alphanumeric(number: 20)])
      allow(parser).to receive(:tailored_profile).and_return(build(:profile))
    end

    context 'when the report contains rules not in the security guide' do
      before { allow(parser).to receive(:version_mismatched?).and_return(false) }

      it 'raises UnknownRuleError' do
        expect { parser.check_for_missing_rules }.to raise_error(described_class::UnknownRuleError)
      end
    end

    context 'when versions are mismatched' do
      before { allow(parser).to receive(:version_mismatched?).and_return(true) }

      it 'does not raise even if unknown rules exist' do
        expect { parser.check_for_missing_rules }.not_to raise_error
      end
    end
  end

  describe '#validate!' do
    context 'when a validation check fails' do
      let(:system) { create(:system, account: user.account, os_major_version: unsupported_os_major_version) }

      it 'raises and does not persist anything' do
        allow(parser).to receive(:save_all_test_result_info)

        expect { parser.validate! }.to raise_error(described_class::OSVersionMismatch)
        expect(parser).not_to have_received(:save_all_test_result_info)
      end
    end

    context 'when all checks pass' do
      before do
        allow(parser).to receive(:check_os_version)
        allow(parser).to receive(:check_for_external_reports)
        allow(parser).to receive(:check_for_missing_benchmark_info)
      end

      it 'runs all validation checks' do
        parser.validate!

        expect(parser).to have_received(:check_os_version)
        expect(parser).to have_received(:check_for_external_reports)
        expect(parser).to have_received(:check_for_missing_benchmark_info)
      end
    end
  end

  describe '#persist!' do
    before do
      allow(parser).to receive(:save_all_test_result_info)
      allow(System).to receive(:transaction).and_yield
    end

    it 'saves the test result info inside a transaction' do
      parser.persist!

      expect(System).to have_received(:transaction)
      expect(parser).to have_received(:save_all_test_result_info)
    end
  end

  # Ingesting a report after an in-place minor upgrade (8.1 -> 8.5): hosted content has no tailoring
  # for the new minor (OSVersionMismatch); minor-agnostic content collapses it onto the .0 tailoring.
  describe '#check_for_missing_tailored_profile after an OS minor upgrade' do
    let(:os_major_version) { 8 }
    let(:assignment_minor) { 1 }
    let(:upgraded_minor) { 5 }

    def ssg(major, minor)
      SupportedSsg.new(os_major_version: major.to_s, os_minor_version: minor.to_s, version: '0.1.40')
    end

    let(:profile) do
      create(:profile, ref_id_suffix: 'standard', os_major_version: os_major_version, supports_minors: supported_minors)
    end
    let(:policy) { create(:policy, account: user.account, os_major_version: os_major_version, profile: profile) }

    # Tailoring is created at the assignment minor, then the system reports the upgraded minor.
    let(:system) do
      create(:system, account: user.account, policy_id: policy.id,
                      os_major_version: os_major_version, os_minor_version: assignment_minor).tap do |sys|
        upgraded = sys.system_profile.deep_dup
        upgraded['operating_system']['minor'] = upgraded_minor
        upgraded['os_release'] = "#{os_major_version}.#{upgraded_minor}"
        sys.update!(system_profile: upgraded)
        sys.reload
      end
    end

    context 'with per-minor (hosted) content that ships no tailoring for the new minor' do
      let(:supported_minors) { [assignment_minor] }

      before do
        allow(SupportedSsg).to receive(:all)
          .and_return([ssg(os_major_version, 0), ssg(os_major_version, assignment_minor)])
      end

      it 'raises OSVersionMismatch reporting the resolved upgraded minor' do
        expect { parser.check_for_missing_tailored_profile }
          .to raise_error(described_class::OSVersionMismatch, /resolved to #{upgraded_minor}/)
      end
    end

    context 'with minor-agnostic (upstream/IoP) content that ships only the .0 datastream' do
      let(:supported_minors) { [0] }

      before { allow(SupportedSsg).to receive(:all).and_return([ssg(os_major_version, 0)]) }

      it 'keeps resolving the re-scan to the single .0 tailoring' do
        expect { parser.check_for_missing_tailored_profile }.not_to raise_error
        expect(parser.tailored_profile)
          .to eq(Tailoring.find_by!(policy: policy, os_minor_version: 0).profile)
      end
    end
  end
end
