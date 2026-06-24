# frozen_string_literal: true

require 'rails_helper'

describe ReportArtifact do
  let(:xml) do
    Array.new(200) do
      %(<xml><TestResult id="#{Faker::Alphanumeric.alphanumeric(number: 8)}"/></xml>)
    end.join
  end

  it 'round-trips the report through pack/unpack' do
    expect(described_class.unpack(described_class.pack(xml))).to eq(xml)
  end

  it 'packs to a JSON/ASCII-safe payload (so it is a safe job argument)' do
    expect(described_class.pack(xml)).to match(%r{\A[A-Za-z0-9+/=]+\z})
  end

  it 'compresses the payload well below the raw report size' do
    expect(described_class.pack(xml).bytesize).to be < xml.bytesize
  end
end
