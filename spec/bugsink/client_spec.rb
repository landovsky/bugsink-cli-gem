# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bugsink::Client do
  let(:config) do
    instance_double(Bugsink::Config,
                    api_key: 'test-key',
                    host: 'https://test.example.com',
                    authorization_header: { 'Authorization' => 'Bearer test-key' })
  end
  let(:client) { described_class.new(config) }

  before do
    allow(config).to receive(:validate!)
  end

  describe '#initialize' do
    it 'validates configuration' do
      expect(config).to receive(:validate!)
      described_class.new(config)
    end

    it 'sets base URI from config host' do
      client
      expect(described_class.base_uri).to eq('https://test.example.com')
    end
  end

  describe 'Response class' do
    describe '#initialize' do
      it 'wraps hash response as array' do
        response = Bugsink::Client::Response.new({ 'id' => 1 })
        expect(response.data).to eq([{ 'id' => 1 }])
      end

      it 'uses array response directly' do
        response = Bugsink::Client::Response.new([{ 'id' => 1 }, { 'id' => 2 }])
        expect(response.data).to eq([{ 'id' => 1 }, { 'id' => 2 }])
      end
    end

    describe '#initialize_from_list' do
      it 'extracts results and next cursor' do
        response = Bugsink::Client::Response.new(nil)
        response.initialize_from_list({ 'results' => [{ 'id' => 1 }], 'next' => 'cursor-123' })
        expect(response.data).to eq([{ 'id' => 1 }])
        expect(response.next_cursor).to eq('cursor-123')
      end
    end

    describe '#has_more?' do
      it 'returns true when next_cursor is present' do
        response = Bugsink::Client::Response.new(nil)
        response.initialize_from_list({ 'results' => [], 'next' => 'cursor-123' })
        expect(response.has_more?).to be true
      end

      it 'returns false when next_cursor is nil' do
        response = Bugsink::Client::Response.new(nil)
        response.initialize_from_list({ 'results' => [] })
        expect(response.has_more?).to be false
      end
    end
  end

  describe 'ClientError' do
    it 'stores code and response' do
      error = Bugsink::Client::ClientError.new('Test error', code: 404, response: 'Not found')
      expect(error.message).to eq('Test error')
      expect(error.code).to eq(404)
      expect(error.response).to eq('Not found')
    end
  end

  describe '#test_connection' do
    it 'returns true on successful connection' do
      allow(described_class).to receive(:get).and_return(
        double(code: 200, parsed_response: [])
      )
      expect(client.test_connection).to be true
    end

    it 'raises ClientError on failure' do
      allow(described_class).to receive(:get).and_return(
        double(code: 401, parsed_response: 'Unauthorized', body: 'Unauthorized')
      )
      expect { client.test_connection }.to raise_error(Bugsink::Client::ClientError)
    end
  end
end
