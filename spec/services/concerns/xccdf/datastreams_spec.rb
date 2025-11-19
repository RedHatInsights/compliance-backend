# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::Datastreams do
  subject(:service) { Class.new { include Xccdf::Datastreams }.new }

  let(:file_path) { '/tmp/fake-datastream.xml' }
  let(:file_contents) { '<xml>mock datastream content</xml>' }
  let(:parser_double) { instance_double('OpenscapParser::DatastreamFile') }

  describe '#op_datastream_file' do
    before do
      allow(File).to receive(:read).with(file_path).and_return(file_contents)
    end

    it 'reads the file and instantiates the parser class' do
      expect(File).to receive(:read)
      expect(OpenscapParser::DatastreamFile).to receive(:new)
        .with(file_contents)
        .and_return(parser_double)

      expect(service.op_datastream_file(file_path)).to eq(parser_double)
    end
  end
end
