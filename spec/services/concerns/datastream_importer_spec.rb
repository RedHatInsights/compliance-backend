# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatastreamImporter do
  describe '#import!' do
    let(:datastream_filename) { 'spec/fixtures/files/ssg-rhel7-ds.xml' }

    subject { DatastreamImporter.new(datastream_filename) }

    it 'imports the datastream' do
      expect(subject).to receive(:save_all_security_guide_info)
      subject.import!
    end
  end
end
