# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::Datastreams do
  subject(:service) { Class.new { include Xccdf::Datastreams }.new }

  let(:fixture_path) { Rails.root.join('spec/fixtures/files/ssg-rhel7-ds.xml') }
  let(:fixture_contents) { file_fixture('ssg-rhel7-ds.xml').read }
  let(:parser_double) { instance_double('OpenscapParser::DatastreamFile') }

  describe '#op_datastream_file' do
    it 'reads the fixture and instantiates the parser class' do
      expect(File).to receive(:read).with(fixture_path).and_return(fixture_contents)
      expect(OpenscapParser::DatastreamFile).to receive(:new)
        .with(fixture_contents)
        .and_return(parser_double)

      expect(service.op_datastream_file(fixture_path)).to eq(parser_double)
    end
  end
end
