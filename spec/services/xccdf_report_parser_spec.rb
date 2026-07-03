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
      it 'raises UnknownRuleError' do
        expect { parser.check_for_missing_rules }.to raise_error(described_class::UnknownRuleError)
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
end
