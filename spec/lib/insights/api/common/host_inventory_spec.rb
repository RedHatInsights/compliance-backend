# frozen_string_literal: true

require 'rails_helper'

describe Insights::Api::Common::HostInventory do
  let(:url) { 'http://inventory:8080' }
  let(:b64_identity) { Base64.strict_encode64(Faker::Lorem.word) }
  let(:connection) { instance_double(Faraday::Connection) }
  let(:inventory) { described_class.new(url: url, b64_identity: b64_identity) }
  let(:host_url) { "#{url}#{Settings.path_prefix}/inventory/v1/hosts" }

  before do
    allow(Insights::Api::Common::Platform).to receive(:connection).and_return(connection)
  end

  describe '#host_ids_by_tags' do
    let(:host_ids) { Array.new(3) { SecureRandom.uuid } }
    let(:tags) { ["#{Faker::Lorem.word}/#{Faker::Lorem.word}=#{Faker::Lorem.word}"] }

    context 'with results fitting in a single page' do
      before do
        allow(connection).to receive(:get).and_return(
          instance_double(Faraday::Response, body: {
            results: host_ids.map { |id| { 'id' => id } }
          }.to_json)
        )
      end

      it 'returns host IDs' do
        expect(inventory.host_ids_by_tags(tags)).to match_array(host_ids)
      end

      it 'sends tags via flat query encoding' do
        inventory.host_ids_by_tags(tags)
        expect(connection).to have_received(:get) do |url, _params, headers|
          expect(url).to include('page=1')
          expect(url).to include('per_page=100')
          expect(url).to include('tags=')
          expect(headers).to include('X-RH-IDENTITY': b64_identity)
        end
      end
    end

    context 'with results spanning multiple pages' do
      let(:page1_ids) { Array.new(100) { SecureRandom.uuid } }
      let(:page2_ids) { Array.new(50) { SecureRandom.uuid } }

      before do
        call_count = 0
        allow(connection).to receive(:get) do
          call_count += 1
          body = if call_count == 1
                   { results: page1_ids.map { |id| { 'id' => id } } }
                 else
                   { results: page2_ids.map { |id| { 'id' => id } } }
                 end
          instance_double(Faraday::Response, body: body.to_json)
        end
      end

      it 'paginates and returns all host IDs' do
        result = inventory.host_ids_by_tags(tags)
        expect(result).to match_array(page1_ids + page2_ids)
      end

      it 'makes exactly 2 requests' do
        inventory.host_ids_by_tags(tags)
        expect(connection).to have_received(:get).twice
      end
    end

    context 'with empty results' do
      before do
        allow(connection).to receive(:get).and_return(
          instance_double(Faraday::Response, body: { results: [] }.to_json)
        )
      end

      it 'returns an empty array' do
        expect(inventory.host_ids_by_tags(tags)).to eq([])
      end
    end

    context 'with nil results key' do
      before do
        allow(connection).to receive(:get).and_return(
          instance_double(Faraday::Response, body: {}.to_json)
        )
      end

      it 'returns an empty array' do
        expect(inventory.host_ids_by_tags(tags)).to eq([])
      end
    end

    context 'with multiple tags' do
      let(:multi_tags) do
        Array.new(2) { "#{Faker::Lorem.word}/#{Faker::Lorem.word}=#{Faker::Lorem.word}" }
      end

      before do
        allow(connection).to receive(:get).and_return(
          instance_double(Faraday::Response, body: {
            results: [{ 'id' => SecureRandom.uuid }]
          }.to_json)
        )
      end

      it 'passes all tags to HBI' do
        inventory.host_ids_by_tags(multi_tags)
        expect(connection).to have_received(:get) do |url, _params, _headers|
          query = url.sub(/^\?/, '')
          multi_tags.each { |tag| expect(query).to include("tags=#{Faraday::Utils.escape(tag)}") }
        end
      end
    end

    context 'when HBI returns an error' do
      before do
        allow(connection).to receive(:get).and_raise(Faraday::ServerError, Faker::Lorem.sentence)
      end

      it 'propagates the exception (fail-closed)' do
        expect { inventory.host_ids_by_tags(tags) }.to raise_error(Faraday::ServerError)
      end
    end

    context 'when HBI returns malformed JSON' do
      before do
        allow(connection).to receive(:get).and_return(
          instance_double(Faraday::Response, body: Faker::Lorem.sentence)
        )
      end

      it 'raises a parse error (fail-closed)' do
        expect { inventory.host_ids_by_tags(tags) }.to raise_error(JSON::ParserError)
      end
    end
  end
end
